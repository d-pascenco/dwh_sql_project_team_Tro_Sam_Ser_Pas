# DWH проект по авиаперелетам

Мы сделали учебное хранилище данных для анализа внутренних авиарейсов США. Проект собирает сырые данные о рейсах и аэропортах, очищает их, строит слой фактов и измерений, а потом готовит витрины для графиков в DataLens.

Основная аналитическая задача: смотреть количество рейсов, отмены, процент отмен, средние задержки и причины задержек в разрезе дат, перевозчиков и аэропортов.

## Стек

- Python
- SQL
- PostgreSQL
- S3 / Object Storage
- Airflow
- dbt
- DataLens

## Как устроен проект

Данные проходят по слоям:

```text
ODS -> STG -> DDS -> DM -> DataLens
```

- `ODS` - принимаем сырые данные почти без изменений.
- `STG` - чистим данные, приводим типы, убираем дубли.
- `DDS` - строим основную модель хранилища: факты и измерения.
- `DM` - делаем витрины, удобные для отчетов и графиков.
- `DataLens` - строим итоговый дашборд.

## Структура репозитория

```text
dags/       Airflow DAG-и
python/     Python-скрипты для загрузки и запуска SQL
sql/        SQL-скрипты по слоям ODS, STG, DDS, DM
dbt/        dbt-модели для STG и DDS
scripts/    скрипты для git pull / git push
```

Локальные файлы с секретами:

```text
config.env
git_config.env
```

## Работа с Git

Один раз даем права на запуск скриптов (сделали для удобства команды):

```bash
cd /home/jovyan/work/dwh_sql_project_team_Tro_Sam_Ser_Pas
chmod +x scripts/git_push.sh
chmod +x scripts/git_pull.sh
```

Подтягиваем актуальную версию:

```bash
./scripts/git_pull.sh
```

Пушим свои изменения:

```bash
./scripts/git_push.sh "текст коммита"
```

Также есть ноутбуки `git_pull.ipynb` и `git_push.ipynb`, где эти команды можно запускать из ячеек.

## Загрузка проекта в Airflow bucket

Для загрузки файлов в bucket `gsb2024airflow` используется:

```text
python/s3/s3_push_AF.py
```
Скрипт загружает проект в командную папку:

```text
Team_Trofimov_Samundzhyan_Serenko_Paschenko/
```

Туда попадают:

```text
python/
sql/
dags/
dbt/
config.env
```

Также папка `dbt/` загружается в корень bucket, потому что STG и DDS DAG-и запускают модели из:

```text
/opt/airflow/dags/dbt
```

## Порядок запуска в Airflow

Запускать DAG-и нужно строго по порядку:

```text
dipaschenko_ods_pipeline_dag
evserenko_stg_pipeline_dag
mvtrofimov_dds_pipeline_dag
dasamundzhyan_dm_pipeline_dag
```

То есть:
```text
ODS -> STG -> DDS -> DM
```

## ODS

ODS - это слой сырых данных. Здесь мы сохраняем данные так, чтобы потом можно было понять, 
из какого файла и из какой строки они пришли.

Схемы:

```text
team_tro_sam_ser_pas_ods
team_tro_sam_ser_pas_etl
```

Таблицы:

- `team_tro_sam_ser_pas_ods.flights_raw` - сырые строки рейсов из S3.
- `team_tro_sam_ser_pas_ods.airports_raw` - сырой справочник аэропортов.
- `team_tro_sam_ser_pas_etl.load_control` - техническая таблица контроля загрузок.

В ODS данные рейсов и аэропортов хранятся в `jsonb`. Дополнительно сохраняются:

- `source` - файл-источник;
- `row_number` - номер строки в файле;
- `upload_id` - номер загрузки;
- `upload_time` - время загрузки.

Для защиты от дублей используется уникальность по `source + row_number`.

SQL-файлы:

```text
sql/ods/001_create_ods_schema.sql
sql/ods/002_create_ods_tables.sql
sql/ods/003_create_etl_control.sql
```

Python-файлы:

```text
python/ods/create_ods_tables.py
python/ods/load_airports_to_ods.py
python/ods/load_flights_to_ods.py
python/ods/run_ods_pipeline.py
```

Airflow DAG:

```text
dags/dipaschenko_ods_pipeline_dag.py
```

Что делает DAG:

1. Создает ODS и ETL-таблицы.
2. Загружает справочник аэропортов.
3. Ищет новые файлы рейсов в S3.
4. Загружает только те файлы, которых еще нет в `flights_raw`.
5. Записывает результат загрузки в `load_control`.

Локальный запуск (на всякий):

```bash
python python/ods/run_ods_pipeline.py
```

## STG

STG - это слой подготовки данных. Здесь сырые JSON-строки превращаются в нормальные колонки.

Схема:

```text
team_tro_sam_ser_pas_stg
```

Основные объекты:

- `flights_clean` - рейсы с нормальными типами колонок.
- `airports_clean` - аэропорты с нормальными типами колонок.
- `flights_deduplicated` - рейсы после удаления дублей.
- `airports_deduplicated` - аэропорты после удаления дублей.
- `flights_success_raw` - выполненные рейсы.
- `flights_cancelled_raw` - отмененные рейсы.

Что делаем в STG:

- достаем поля из `jsonb`;
- приводим даты, числа и коды к нормальному виду;
- приводим коды аэропортов и перевозчиков к верхнему регистру;
- убираем дубли рейсов;
- убираем дубли аэропортов по `iata_code`;
- делим рейсы на выполненные и отмененные.

SQL-файлы:

```text
sql/stg/001_create_stg_schema.sql
sql/stg/002_create_stg_tables.sql
sql/stg/003_upload_stg_tables.sql
sql/stg/004_deduplication_stg_tables.sql
sql/stg/005_division_stg_tables.sql
```

dbt-модели:

```text
dbt/models/evserenko/
```

Airflow DAG:

```text
dags/evserenko_stg_pipeline_dag.py
```

В Airflow этот слой запускается через dbt:

```bash
cd /opt/airflow/dags/dbt
dbt run --select path:models/evserenko
```

Локальный запуск SQL/Python-варианта:

```bash
python python/stg/run_stg_pipeline.py
```

## DDS

DDS - это основной слой хранилища. Здесь мы строим модель со справочниками и фактами.

Схема:

```text
team_tro_sam_ser_pas_dds
```

Измерения:

| Таблица | Что хранит |
|---------|------------|
| `dim_date` | даты рейсов |
| `dim_carrier` | авиаперевозчиков |
| `dim_airport` | аэропорты |
| `dim_aircraft` | самолеты по `tail_num` |

Факты:

| Таблица | Что хранит |
|---------|------------|
| `fct_flights` | выполненные рейсы |
| `fct_cancelled_flights` | отмененные рейсы |

В фактах есть ключи на измерения:

- дата;
- перевозчик;
- аэропорт вылета;
- аэропорт прилета;
- самолет.

Также есть показатели:

- задержка вылета;
- задержка прилета;
- расстояние;
- задержки по причинам;
- код причины отмены для отмененных рейсов.

Для требования по времени в DDS добавлены поля:

- `flight_dttm_local` - локальная дата и время вылета;
- `scheduled_dep_dttm_local` - плановая дата и время вылета;
- `actual_dep_dttm_local` - фактическая дата и время вылета;
- `scheduled_arr_dttm_local` - плановая дата и время прилета;
- `sched_dttm_local` - плановая дата и время вылета для отмененных рейсов.

`actual_dep_dttm_local` считается как:

```text
плановое время вылета + задержка вылета в минутах
```

Часовой пояс берется по региону аэропорта. Для неизвестных регионов используется `UTC`.

SQL-файлы:

```text
sql/dds/001_create_dds_schema.sql
sql/dds/002_create_dim_tables.sql
sql/dds/003_create_fct_tables.sql
sql/dds/004_load_dim_tables.sql
sql/dds/005_load_fct_flights.sql
sql/dds/006_create_cancelled_view.sql
```

dbt-модели:

```text
dbt/models/mvtrofimov/
```

Airflow DAG:

```text
dags/mvtrofimov_dds_pipeline_dag.py
```

В Airflow этот слой запускается через dbt:

```bash
cd /opt/airflow/dags/dbt
dbt run --select path:models/mvtrofimov
```

Локальный запуск SQL/Python-варианта:

```bash
python python/dds/run_dds_pipeline.py
```

## DM

DM - это слой витрин для аналитики и DataLens. 
Здесь данные уже собраны в удобном для графиков виде.

Схема:

```text
team_tro_sam_ser_pas_dm
```

Витрины:

- `flight_overview` - общая витрина по рейсам, отменам и задержкам.
- `delay_reasons` - витрина по причинам задержек.

В `flight_overview` считаются:

- количество выполненных рейсов;
- количество отмененных рейсов;
- общее количество рейсов;
- процент отмен;
- средняя задержка вылета;
- средняя задержка прилета;
- сумма задержек;
- показатели по датам, перевозчикам и аэропортам.

В `delay_reasons` задержки раскладываются по причинам:

- задержка по вине перевозчика;
- задержка из-за погоды;
- задержка NAS;
- задержка безопасности;
- задержка из-за позднего прибытия самолета.

SQL-файлы:

```text
sql/dm/001_create_dm_schema.sql
sql/dm/002_create_dm_flight_overview.sql
sql/dm/003_create_dm_delay_reasons.sql
sql/dm/004_check_dm_metrics.sql
sql/dm/005_datalens_chart_queries.sql
```

Airflow DAG:

```text
dags/dasamundzhyan_dm_pipeline_dag.py
```

DM DAG запускает обычные SQL-файлы через `psql`. Это отличается от STG и DDS, потому что STG/DDS сделаны через dbt, а DM у нас оформлен как набор SQL-скриптов.

DAG выполняет:

```text
001_create_dm_schema.sql
002_create_dm_flight_overview.sql
003_create_dm_delay_reasons.sql
004_check_dm_metrics.sql
```

Файл `005_datalens_chart_queries.sql` не запускается в DAG. Он нужен как набор готовых запросов для графиков.

## DataLens

Для визуализации данных использовался сервис Yandex DataLens. Подключение создавалось к PostgreSQL, в котором находятся подготовленные DM-витрины проекта.

### Подключение к PostgreSQL

Подключение к PostgreSQL выполнялось с помощью стандартного коннектора PostgreSQL в Yandex DataLens. В воркбуке Flights Project было создано новое подключение, после чего в параметрах были указаны хост, порт, база данных, пользователь и схема с DM-витринами.

После создания подключения в DataLens были выбраны две DM-витрины:

- `team_tro_sam_ser_pas_dm.flight_overview`
- `team_tro_sam_ser_pas_dm.delay_reasons`

На основе этих витрин были созданы два датасета:

- `DM Flight Overview`
- `DM Delay Reasons`

Датасет DM Flight Overview используется для анализа количества рейсов, отмен и задержек по датам, перевозчикам и аэропортам.

Датасет DM Delay Reasons используется для анализа причин задержек.

В DataLens были добавлены вычисляемые поля:

- `cancellation_rate_pct` — процент отменённых рейсов;
- `avg_dep_delay_rate_min` — средняя задержка вылета.

В DataLens были построены следующие графики:

- количество рейсов по датам;
- процент отмен по перевозчикам;
- средняя задержка вылета по перевозчикам;
- причины задержек;
- задержки по аэропортам.

Итоговый дашборд называется `Аналитика авиарейсов`.
```
