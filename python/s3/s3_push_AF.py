import os
from pathlib import Path

import boto3
from dotenv import load_dotenv


PROJECT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_DIR / "config.env", override=True)

S3_BUCKET = os.getenv("S3_AIRFLOW_BUCKET")
S3_TEAM_PREFIX = os.getenv("S3_TEAM_PREFIX", "Team_Trofimov_Samundzhyan_Serenko_Paschenko")

EXCLUDE_PARTS = {
    "__pycache__",
    ".ipynb_checkpoints",
    ".git",
}

EXCLUDE_SUFFIXES = {
    ".pyc",
}

# Тут папки, что мы выбираем для пуша в S3 AF
PROJECT_PATHS_TO_UPLOAD = [
    "python",
    "sql",
    "config.env",
    "dags",
    "dbt",
    "stg"
]

# Эти папки дополнительно грузим в корень bucket.
ROOT_PATHS_TO_UPLOAD = [
    "dbt",
]

# Какие DAG-файлы грузим в корень bucket
DAG_FILES_TO_UPLOAD = [
    "dags/dipaschenko_ods_pipeline_dag.py",
    "dags/evserenko_stg_pipeline_dag.py",
    "dags/mvtrofimov_dds_pipeline_dag.py",
]


def get_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=os.getenv("S3_ENDPOINT_URL"),
        aws_access_key_id=os.getenv("S3_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("S3_SECRET_ACCESS_KEY"),
    )


def should_upload(path: Path) -> bool:
    if not path.is_file():
        return False

    if any(part in EXCLUDE_PARTS for part in path.parts):
        return False

    if path.suffix in EXCLUDE_SUFFIXES:
        return False

    return True


def upload_file(s3, local_path: Path, s3_key: str):
    s3.upload_file(str(local_path), S3_BUCKET, s3_key)
    print(f"uploaded: {local_path.relative_to(PROJECT_DIR)} -> s3://{S3_BUCKET}/{s3_key}")


def upload_path_to_team_folder(s3, relative_path: str):
    local_path = PROJECT_DIR / relative_path

    if not local_path.exists():
        print(f"skip, not found: {relative_path}")
        return

    if local_path.is_file():
        s3_key = f"{S3_TEAM_PREFIX}/{relative_path}"
        upload_file(s3, local_path, s3_key)
        return

    for path in local_path.rglob("*"):
        if not should_upload(path):
            continue

        rel = path.relative_to(PROJECT_DIR).as_posix()
        s3_key = f"{S3_TEAM_PREFIX}/{rel}"
        upload_file(s3, path, s3_key)


def upload_dag_to_bucket_root(s3, relative_path: str):
    local_path = PROJECT_DIR / relative_path

    if not local_path.exists():
        print(f"skip dag, not found: {relative_path}")
        return

    s3_key = local_path.name
    upload_file(s3, local_path, s3_key)


def upload_path_to_bucket_root(s3, relative_path: str):
    local_path = PROJECT_DIR / relative_path

    if not local_path.exists():
        print(f"skip root path, not found: {relative_path}")
        return

    if local_path.is_file():
        upload_file(s3, local_path, relative_path)
        return

    for path in local_path.rglob("*"):
        if not should_upload(path):
            continue

        s3_key = path.relative_to(PROJECT_DIR).as_posix()
        upload_file(s3, path, s3_key)


def main():
    if not S3_BUCKET:
        raise ValueError("S3_AIRFLOW_BUCKET is empty")

    s3 = get_s3_client()

    print("upload project files to team folder")
    for relative_path in PROJECT_PATHS_TO_UPLOAD:
        upload_path_to_team_folder(s3, relative_path)

    print("upload root paths to bucket root")
    for relative_path in ROOT_PATHS_TO_UPLOAD:
        upload_path_to_bucket_root(s3, relative_path)

    print("upload DAG files to bucket root")
    for relative_path in DAG_FILES_TO_UPLOAD:
        upload_dag_to_bucket_root(s3, relative_path)

    print("done")


if __name__ == "__main__":
    main()
