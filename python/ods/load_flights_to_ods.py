import os
import csv
import gzip
from io import TextIOWrapper
from pathlib import Path

import boto3
import psycopg2
from psycopg2.extras import execute_values, Json
from dotenv import load_dotenv


PROJECT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_DIR / "config.env", override=True)

FLOW_NAME = "load_flights_to_ods"
S3_FLIGHTS_PREFIX = "flights_us_data/"


def get_connection():
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=os.getenv("PG_PORT"),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD")
    )


def get_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=os.getenv("S3_ENDPOINT_URL"),
        aws_access_key_id=os.getenv("S3_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("S3_SECRET_ACCESS_KEY"),
    )


def get_next_upload_id(conn) -> int:
    with conn.cursor() as cur:
        cur.execute("""
            select coalesce(max(upload_id), 0) + 1
            from team_tro_sam_ser_pas_ods.flights_raw;
        """)
        return cur.fetchone()[0]


def get_s3_flight_files():
    """
    Возвращает список всех csv.gz файлов рейсов из S3.
    """
    s3 = get_s3_client()
    bucket = os.getenv("S3_SOURCE_BUCKET")

    files = []
    continuation_token = None

    while True:
        params = {
            "Bucket": bucket,
            "Prefix": S3_FLIGHTS_PREFIX,
            "MaxKeys": 1000,
        }

        if continuation_token:
            params["ContinuationToken"] = continuation_token

        response = s3.list_objects_v2(**params)

        for obj in response.get("Contents", []):
            key = obj["Key"]
            if key.endswith(".csv.gz"):
                files.append(key)

        if response.get("IsTruncated"):
            continuation_token = response.get("NextContinuationToken")
        else:
            break

    return sorted(files)


def get_loaded_sources(conn):
    """
    Возвращает set уже загруженных source из flights_raw.
    """
    with conn.cursor() as cur:
        cur.execute("""
            select distinct source
            from team_tro_sam_ser_pas_ods.flights_raw;
        """)
        return {row[0] for row in cur.fetchall()}


def read_csv_gz_from_s3(s3_key: str):
    """
    Читает csv.gz файл из S3 построчно.
    Возвращает пары: row_number, row_dict.
    """
    s3 = get_s3_client()

    response = s3.get_object(
        Bucket=os.getenv("S3_SOURCE_BUCKET"),
        Key=s3_key
    )

    body = response["Body"]

    with gzip.GzipFile(fileobj=body) as gz:
        with TextIOWrapper(gz, encoding="utf-8") as text_file:
            reader = csv.DictReader(text_file)
            for row_number, row in enumerate(reader, start=1):
                yield row_number, row


def update_load_control(conn, last_loaded_source, upload_id, inserted_rows, status="SUCCESS", error_text=None):
    """
    Обновляет техническую таблицу контроля загрузок.
    """
    with conn.cursor() as cur:
        cur.execute(
            """
            insert into team_tro_sam_ser_pas_etl.load_control (
                flow_name,
                last_success_upload,
                last_loaded_source,
                last_upload_id,
                row_count_uploaded,
                status,
                error_text,
                updated_dttm
            )
            values (
                %s,
                case when %s = 'SUCCESS' then now() else null end,
                %s,
                %s,
                %s,
                %s,
                %s,
                now()
            )
            on conflict (flow_name) do update set
                last_success_upload = case
                    when excluded.status = 'SUCCESS'
                    then excluded.last_success_upload
                    else team_tro_sam_ser_pas_etl.load_control.last_success_upload
                end,
                last_loaded_source = excluded.last_loaded_source,
                last_upload_id = excluded.last_upload_id,
                row_count_uploaded = excluded.row_count_uploaded,
                status = excluded.status,
                error_text = excluded.error_text,
                updated_dttm = excluded.updated_dttm;
            """,
            (
                FLOW_NAME,
                status,
                last_loaded_source,
                upload_id,
                inserted_rows,
                status,
                error_text,
            ),
        )


def load_one_flight_file(conn, s3_key: str, upload_id: int) -> int:
    """
    Загружает один csv.gz файл из S3 в flights_raw.
    Возвращает количество строк, которые оказались в таблице с этим upload_id.
    """
    values = []

    for row_number, row in read_csv_gz_from_s3(s3_key):
        values.append(
            (
                s3_key,
                row_number,
                Json(row),
                upload_id,
            )
        )

    if not values:
        return 0

    with conn.cursor() as cur:
        execute_values(
            cur,
            """
            insert into team_tro_sam_ser_pas_ods.flights_raw
                (source, row_number, data, upload_id)
            values %s
            on conflict (source, row_number) do nothing;
            """,
            values,
            page_size=1000,
        )

        cur.execute("""
            select count(*)
            from team_tro_sam_ser_pas_ods.flights_raw
            where source = %s
              and upload_id = %s;
        """, (s3_key, upload_id))

        inserted_rows = cur.fetchone()[0]

    return inserted_rows


def load_flights():
    """
    Основной процесс:
    1. Получает список файлов в S3.
    2. Получает список уже загруженных файлов.
    3. Загружает только новые файлы.
    """
    s3_files = get_s3_flight_files()

    if not s3_files:
        print("Файлы рейсов в S3 не найдены")
        return

    print(f"Найдено файлов в S3: {len(s3_files)}")

    with get_connection() as conn:
        loaded_sources = get_loaded_sources(conn)

        new_files = [file for file in s3_files if file not in loaded_sources]

        print(f"Уже загружено файлов: {len(loaded_sources)}")
        print(f"Новых файлов для загрузки: {len(new_files)}")

        if not new_files:
            print("Новых файлов нет. Загрузка не требуется.")
            update_load_control(
                conn=conn,
                last_loaded_source=None,
                upload_id=None,
                inserted_rows=0,
                status="SUCCESS",
                error_text="No new files"
            )
            conn.commit()
            return

        total_inserted_rows = 0
        last_loaded_source = None
        last_upload_id = None

        for s3_key in new_files:
            try:
                upload_id = get_next_upload_id(conn)

                print(f"Загружается файл: {s3_key}, upload_id={upload_id}")

                inserted_rows = load_one_flight_file(
                    conn=conn,
                    s3_key=s3_key,
                    upload_id=upload_id
                )

                total_inserted_rows += inserted_rows
                last_loaded_source = s3_key
                last_upload_id = upload_id

                update_load_control(
                    conn=conn,
                    last_loaded_source=s3_key,
                    upload_id=upload_id,
                    inserted_rows=inserted_rows,
                    status="SUCCESS",
                    error_text=None
                )

                conn.commit()

                print(f"Файл загружен: {s3_key}. Строк вставлено: {inserted_rows}")

            except Exception as e:
                conn.rollback()

                update_load_control(
                    conn=conn,
                    last_loaded_source=s3_key,
                    upload_id=last_upload_id,
                    inserted_rows=0,
                    status="FAILED",
                    error_text=f"{type(e).__name__}: {e}"
                )

                conn.commit()

                print(f"Ошибка загрузки файла: {s3_key}")
                print(type(e).__name__)
                print(e)
                raise

    print(f"Загрузка завершена. Всего новых строк: {total_inserted_rows}")
    print(f"Последний загруженный файл: {last_loaded_source}")
    print(f"Последний upload_id: {last_upload_id}")


if __name__ == "__main__":
    try:
        load_flights()
    except Exception as e:
        print("не загрузилось")
        print(type(e).__name__)
        print(e)
        raise