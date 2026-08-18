from create_stg_tables import run_sql_file, PROJECT_DIR

def run_stg_pipeline():
    print("Создание и обработка STG-схем и таблиц")

    sql_files = [
        PROJECT_DIR / "sql/stg/001_create_stg_schema.sql",
        PROJECT_DIR / "sql/stg/002_create_stg_tables.sql",
        PROJECT_DIR / "sql/stg/003_upload_stg_tables.sql",
        PROJECT_DIR / "sql/stg/004_deduplication_stg_tables.sql",
        PROJECT_DIR / "sql/stg/005_division_stg_tables.sql",
    ]

    for sql_file in sql_files:
        run_sql_file(sql_file)

if __name__ == "__main__":
    run_stg_pipeline()
