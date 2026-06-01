# DWH Проект

## Цель

Разработка хранилища данных для анализа авиаперелётов.

## Стек

- Python
- SQL
- PostgreSQL
- S3 / Object Storage
- Airflow
- dbt
- DataLens

## Структура репозитория

- `dags/` — Airflow DAG-файлы
- `python/` — Python-скрипты для загрузки и обработки данных
- `sql/` — SQL-скрипты для ODS, STG, DDS, DM
- `dbt/` — dbt-проект
- `report/` — материалы отчёта
- `screenshots/` — скриншоты успешных запусков и дашбордов
- `data/` — локальные данные, не коммитятся в GitHub

## Терминал

В JupyterLab откройте встроенный терминал: File → New → Terminal или в launcher выберите Terminal.

Для работы с гитхабом, нужно дать права на запуск скриптов:
```
cd /home/jovyan/work/dwh_sql_project_team_Tro_Sam_Ser_Pas
chmod +x scripts/git_push.sh
chmod +x scripts/git_pull.sh
```

## Секреты

Для локальных настроек используется файлы:

```text
config.env
git_config.env
```

Подтянуть актуальную версию из гитхаб:

```
./scripts/git_pull.sh
```

Запушить свои наработки:

```
./scripts/git_push.sh название коммита своё
```

Для удобства сделаны два ноутбука в ячейках которых запускаются команды пуша и пулла:
```text
git_pull.ipynb 
git_push.ipynb
```

Далее нужно настроить один раз имя и email для пушей командами:
```
git config --global user.name "Dmitri Pascenco"
git config --global user.email "твой_email_от_GitHub"
```
Введя эти команды проверьте, что всё применилось:
```
git config --global --list
```
---


# ODS, загрузка данных в S3 и Airflow

ODS-блок отвечает за первичную загрузку данных в PostgreSQL.

## Используемые схемы

В базе `dwh_training` используются схемы:

```text
team_tro_sam_ser_pas_ods
team_tro_sam_ser_pas_etl
```

## Таблицы

`team_tro_sam_ser_pas_ods.flights_raw` -- хранит сырые строки рейсов из S3 `gsbdwhdata/flights_us_data/YYYY-MM-DD/flights_YYYY-MM-DD.csv.gz`

`team_tro_sam_ser_pas_ods.airports_raw` -- хранит сырой справочник аэропортов https://ourairports.com/data/airports.csv


`team_tro_sam_ser_pas_etl.load_control` -- хранит техническую информацию о загрузках: поток, источник, `upload_id`, количество строк, статус и ошибки.

В таблицах `flights_raw` и `airports_raw` используется защита от дублей.

## SQL-скрипты ODS

Файлы находятся в `sql/ods/`

```text
001_create_ods_schema.sql    — создание ODS и ETL схем
002_create_ods_tables.sql    — создание flights_raw и airports_raw
003_create_etl_control.sql   — создание load_control
```

## Python-скрипты ODS

Файлы находятся в `python/ods/`

```text
create_ods_tables.py      — выполняет DDL-скрипты из sql/ods/
load_airports_to_ods.py   — загружает airports.csv в airports_raw
load_flights_to_ods.py    — загружает новые файлы рейсов из S3 в flights_raw
run_ods_pipeline.py       — запускает полный ODS pipeline
```

## Инкрементальная загрузка

`load_flights_to_ods.py`:

1. получает список файлов из S3 по префиксу `flights_us_data/`;
2. проверяет, какие `source` уже есть в `flights_raw`;
3. загружает только новые файлы;
4. обновляет `load_control`.

## Локальный запуск ODS pipeline

Из корня проекта:

```bash
cd /home/jovyan/work/dwh_sql_project_team_Tro_Sam_Ser_Pas
python python/ods/run_ods_pipeline.py
```

# Airflow

DAG для запуска ODS pipeline `dags/dipaschenko_ods_pipeline_dag.py`

Имя DAG в Airflow `dipaschenko_ods_pipeline_dag`

## Загрузка файлов в Airflow bucket

Для загрузки нужных файлов в bucket `gsb2024airflow` используется `python/s3/s3_push_AF.py`

Скрипт загружает:

```text
python/ods/     → Team_Trofimov_Samundzhyan_Serenko_Paschenko/python/ods/
sql/ods/        → Team_Trofimov_Samundzhyan_Serenko_Paschenko/sql/ods/
config.env      → Team_Trofimov_Samundzhyan_Serenko_Paschenko/config.env
DAG-файл        → корень bucket gsb2024airflow
```

# dbt
Командная папка для dbt-моделей в бакете `dbt/models/dwh_sql_project_team_Tro_Sam_Ser_Pas/`