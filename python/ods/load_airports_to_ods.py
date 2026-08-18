import os
import csv
import requests
from io import StringIO
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_values, Json
from dotenv import load_dotenv

PROJECT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_DIR / "config.env", override=True)

AIRPORTS_URL = "https://ourairports.com/data/airports.csv"
SOURCE_NAME = AIRPORTS_URL
FLOW_NAME = "load_airports_to_ods"

def get_connection():
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=os.getenv("PG_PORT"),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD")
    )

def get_next_upload_id(conn) -> int:
    with conn.cursor() as cur:
        cur.execute("""
            select coalesce(max(upload_id), 0) + 1
            from team_tro_sam_ser_pas_ods.airports_raw;
        """)
        return cur.fetchone()[0]

def load_airports():
    response = requests.get(AIRPORTS_URL, timeout=60)
    response.raise_for_status()

    csv_text = response.text
    reader = csv.DictReader(StringIO(csv_text))

    rows = list(reader)

    if not rows:
        print("No rows found in airports.csv")
        return

    with get_connection() as conn:
        upload_id = get_next_upload_id(conn)

        values = [
            (
                SOURCE_NAME,
                row_number,
                Json(row),
                upload_id,
            )
            for row_number, row in enumerate(rows, start=1)
        ]

        with conn.cursor() as cur:
            execute_values(
                cur,
                """
                insert into team_tro_sam_ser_pas_ods.airports_raw
                    (source, row_number, data, upload_id)
                values %s
                on conflict (source, row_number) do nothing;
                """,
                values,
                page_size=1000,
            )

            inserted_rows = cur.rowcount

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
                    now(),
                    %s,
                    %s,
                    %s,
                    'SUCCESS',
                    null,
                    now()
                )
                on conflict (flow_name) do update set
                    last_success_upload = excluded.last_success_upload,
                    last_loaded_source = excluded.last_loaded_source,
                    last_upload_id = excluded.last_upload_id,
                    row_count_uploaded = excluded.row_count_uploaded,
                    status = excluded.status,
                    error_text = excluded.error_text,
                    updated_dttm = excluded.updated_dttm;
                """,
                (
                    FLOW_NAME,
                    SOURCE_NAME,
                    upload_id,
                    inserted_rows,
                ),
            )

        conn.commit()

    print(f"аэропорты загружены: upload_id: {upload_id}. Всего строк: {inserted_rows}")

if __name__ == "__main__":
    load_airports()
