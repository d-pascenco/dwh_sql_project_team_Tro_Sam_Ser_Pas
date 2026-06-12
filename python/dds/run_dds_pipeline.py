from create_dds_tables import run_sql_file, PROJECT_DIR


def run_dds_pipeline():
    print("Создание и загрузка DDS-схем, измерений и фактов")

    sql_files = [
        PROJECT_DIR / "sql/dds/001_create_dds_schema.sql",
        PROJECT_DIR / "sql/dds/002_create_dim_tables.sql",
        PROJECT_DIR / "sql/dds/003_create_fct_tables.sql",
        PROJECT_DIR / "sql/dds/004_load_dim_tables.sql",
        PROJECT_DIR / "sql/dds/005_load_fct_flights.sql",
        PROJECT_DIR / "sql/dds/006_create_cancelled_view.sql",
    ]

    for sql_file in sql_files:
        run_sql_file(sql_file)

    print("DDS pipeline завершён")


if __name__ == "__main__":
    run_dds_pipeline()
