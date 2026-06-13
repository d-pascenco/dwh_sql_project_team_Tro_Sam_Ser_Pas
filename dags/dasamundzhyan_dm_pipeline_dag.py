from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator


with DAG(
    dag_id="dasamundzhyan_dm_pipeline_dag",
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["dwh", "dm", "team_tro_sam_ser_pas"],
) as dag:

    run_dm_pipeline = BashOperator(
        task_id="run_dm_pipeline",
        bash_command="""
        set -e

        if [ -f /opt/airflow/dags/config.env ]; then
            CONFIG_FILE=/opt/airflow/dags/config.env
        elif [ -f /opt/airflow/dags/dwh_sql_project_team_Tro_Sam_Ser_Pas/config.env ]; then
            CONFIG_FILE=/opt/airflow/dags/dwh_sql_project_team_Tro_Sam_Ser_Pas/config.env
        elif [ -f /opt/airflow/dags/Team_Trofimov_Samundzhyan_Serenko_Paschenko/config.env ]; then
            CONFIG_FILE=/opt/airflow/dags/Team_Trofimov_Samundzhyan_Serenko_Paschenko/config.env
        else
            echo "config.env was not found"
            exit 1
        fi

        set -a
        source "$CONFIG_FILE"
        set +a

        if [ -d /opt/airflow/dags/sql/dm ]; then
            DM_SQL_DIR=/opt/airflow/dags/sql/dm
        elif [ -d /opt/airflow/dags/dwh_sql_project_team_Tro_Sam_Ser_Pas/sql/dm ]; then
            DM_SQL_DIR=/opt/airflow/dags/dwh_sql_project_team_Tro_Sam_Ser_Pas/sql/dm
        elif [ -d /opt/airflow/dags/Team_Trofimov_Samundzhyan_Serenko_Paschenko/sql/dm ]; then
            DM_SQL_DIR=/opt/airflow/dags/Team_Trofimov_Samundzhyan_Serenko_Paschenko/sql/dm
        else
            echo "DM SQL directory was not found"
            exit 1
        fi

        for sql_file in \
            001_create_dm_schema.sql \
            002_create_dm_flight_overview.sql \
            003_create_dm_delay_reasons.sql \
            004_check_dm_metrics.sql
        do
            echo "Running ${DM_SQL_DIR}/${sql_file}"
            PGPASSWORD="$PG_PASSWORD" psql \
                -v ON_ERROR_STOP=1 \
                -P pager=off \
                -h "$PG_HOST" \
                -p "$PG_PORT" \
                -U "$PG_USER" \
                -d "$PG_DATABASE" \
                -f "${DM_SQL_DIR}/${sql_file}"
        done
        """,
    )
