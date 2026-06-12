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


# DDS, детальный слой данных

DDS-блок строит звёздную схему (dimensions + facts) на основе STG.

## Используемая схема

```text
team_tro_sam_ser_pas_dds
```

## Измерения (dimensions)

| Таблица | Источник STG | Ключ |
|---------|--------------|------|
| `dim_date` | `flights_deduplicated.flight_dt` | `date_sk` (YYYYMMDD) |
| `dim_carrier` | `flights_deduplicated.carrier_code` | `carrier_sk` |
| `dim_airport` | `airports_deduplicated` + коды из рейсов | `airport_sk` |
| `dim_aircraft` | `flights_deduplicated.tail_num` | `aircraft_sk` |

## Факты (facts)

| Объект | Источник STG | Тип |
|--------|--------------|-----|
| `fct_flights` | `flights_success_raw` | таблица |
| `fct_cancelled_flights` | `flights_cancelled_raw` | представление |

Факты содержат суррогатные ключи измерений и метрики задержек, расстояния и времени.

## SQL-скрипты DDS

Файлы находятся в `sql/dds/`:

```text
001_create_dds_schema.sql    — создание схемы DDS
002_create_dim_tables.sql    — DDL измерений
003_create_fct_tables.sql    — DDL фактов
004_load_dim_tables.sql      — загрузка измерений из STG
005_load_fct_flights.sql     — загрузка фактов выполненных рейсов
006_create_cancelled_view.sql — представление отменённых рейсов
```

## Python-скрипты DDS

Файлы находятся в `python/dds/`:

```text
create_dds_tables.py   — выполняет SQL-скрипты (psycopg2)
run_dds_pipeline.py    — запускает полный DDS pipeline
```

## Локальный запуск DDS pipeline

Из корня проекта (после успешного STG):

```bash
cd /home/jovyan/work/dwh_sql_project_team_Tro_Sam_Ser_Pas
python python/dds/run_dds_pipeline.py
```

## Airflow

DAG для запуска DDS pipeline: `dags/trofimov_dds_pipeline_dag.py`

Имя DAG в Airflow: `trofimov_dds_pipeline_dag`

Запускает dbt-модели из `dbt/models/trofimov/` (аналогично STG).

## dbt-модели DDS

```text
dbt/models/trofimov/
  team_Tro_Sam_Ser_Pas_dds_dim_date.sql
  team_Tro_Sam_Ser_Pas_dds_dim_carrier.sql
  team_Tro_Sam_Ser_Pas_dds_dim_airport.sql
  team_Tro_Sam_Ser_Pas_dds_dim_aircraft.sql
  team_Tro_Sam_Ser_Pas_dds_fct_flights.sql
  team_Tro_Sam_Ser_Pas_dds_fct_cancelled_flights.sql
```

## Для следующего участника (DM / DataLens)

DDS готов для построения витрин DM. Примерные join-ы:

```sql
-- выполненные рейсы с атрибутами
select
    f.*,
    d.year_num, d.month_name,
    c.carrier_code,
    origin.iata_code as origin_code, origin.municipality as origin_city,
    dest.iata_code as dest_code, dest.municipality as dest_city
from team_tro_sam_ser_pas_dds.fct_flights f
join team_tro_sam_ser_pas_dds.dim_date d on f.date_sk = d.date_sk
join team_tro_sam_ser_pas_dds.dim_carrier c on f.carrier_sk = c.carrier_sk
join team_tro_sam_ser_pas_dds.dim_airport origin on f.origin_airport_sk = origin.airport_sk
join team_tro_sam_ser_pas_dds.dim_airport dest on f.dest_airport_sk = dest.airport_sk;
```

Порядок запуска пайплайнов: ODS → STG → DDS → DM.

