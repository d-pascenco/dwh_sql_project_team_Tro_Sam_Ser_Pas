import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


PROJECT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_DIR / "config.env", override=True)


def get_connection():
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=os.getenv("PG_PORT"),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD")
    )


def run_sql_file(path: Path) -> None:
    sql = path.read_text(encoding="utf-8")

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

    print(f"Выполнено: {path}")


if __name__ == "__main__":
    sql_files = [
        PROJECT_DIR / "sql/ods/001_create_stg_schema.sql",
        PROJECT_DIR / "sql/ods/002_create_stg_tables.sql",
    ]

    for file in sql_files:
        run_sql_file(file)

    print("Создалось, наконецто")