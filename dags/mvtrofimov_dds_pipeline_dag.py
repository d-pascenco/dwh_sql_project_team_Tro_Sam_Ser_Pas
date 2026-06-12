from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator


with DAG(
    dag_id="mvtrofimov_dds_pipeline_dag",
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["dwh", "dds", "team_tro_sam_ser_pas"],
) as dag:

    run_dds_pipeline = BashOperator(
        task_id="run_dds_pipeline",
        bash_command="""
        cd /opt/airflow/dags/dbt &&
        dbt run --select path:models/mvtrofimov
        """,
    )
