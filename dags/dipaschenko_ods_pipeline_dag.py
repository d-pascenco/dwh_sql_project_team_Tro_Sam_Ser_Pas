from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="dipaschenko_ods_pipeline_dag",
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["dwh", "ods", "team_tro_sam_ser_pas"],
) as dag:

    run_ods_pipeline = BashOperator(
        task_id="run_ods_pipeline",
        bash_command="""
        cd /opt/airflow/dags/Team_Trofimov_Samundzhyan_Serenko_Paschenko &&
        python python/ods/run_ods_pipeline.py
        """,
    )