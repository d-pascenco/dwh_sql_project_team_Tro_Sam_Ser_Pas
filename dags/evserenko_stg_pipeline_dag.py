from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator


with DAG(
    dag_id="evserenko_stg_pipeline_dag",
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["dwh", "stg", "team_tro_sam_ser_pas"],
) as dag:

    run_stg_pipeline = BashOperator(
        task_id="run_stg_pipeline",
        bash_command="""
        cd /opt/airflow/dags/dbt &&
        dbt run --select path:models/evserenko
        """,
    )