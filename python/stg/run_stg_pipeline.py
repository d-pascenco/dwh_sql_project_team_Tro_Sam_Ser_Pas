from create_stg_tables import run_sql_file, PROJECT_DIR
#from load_airports_to_ods import load_airports
#from load_flights_to_ods import load_flights


def run_stg_pipeline():
    print("1. Создание STG-схем и таблиц")

    sql_files = [
        PROJECT_DIR / "sql/ods/001_create_stg_schema.sql",
        PROJECT_DIR / "sql/ods/002_create_stg_tables.sql",
    ]

    for sql_file in sql_files:
        run_sql_file(sql_file)
'''
    print("2. Загрузка справочника аэропортов")
    load_airports()

    print("3. Загрузка рейсов из S3")
    load_flights()

    print("ODS pipeline завершён")
'''

if __name__ == "__main__":
    run_stg_pipeline()