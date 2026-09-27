# Хранилище данных по авиаперелётам

Учебный командный проект по построению хранилища данных для анализа внутренних авиарейсов США. Система загружает сведения о рейсах и аэропортах, преобразует их по слоям хранилища и формирует витрины для Yandex DataLens.

Основные аналитические показатели:

- количество выполненных и отменённых рейсов;
- процент отмен;
- средняя задержка вылета и прилёта;
- распределение задержек по причинам;
- показатели по датам, перевозчикам и аэропортам.

## Об учебном проекте

Проект выполнен командой из четырёх студентов первого курса магистратуры Национального исследовательского университета "Высшая школа экономики" в рамках образовательной программы "Магистр по наукам о данных", которая в настоящее время носит название "ПРИНТ".

- [НИУ ВШЭ](https://www.hse.ru/)
- [Образовательная программа](https://www.hse.ru/ma/mds/)

## About the academic project

This project was completed by a team of four first-year master's students at HSE University as part of the Master of Data Science programme, currently known as "ANNT" (Applied Neural Network Technologies).

- [HSE University](https://www.hse.ru/en/)
- [Master's programme](https://www.hse.ru/en/ma/mds/)

## Архитектура

```text
S3 -> ODS -> STG -> DDS -> DM -> DataLens
```

| Слой | Назначение |
|------|------------|
| ODS | Хранение исходных строк в JSONB и метаданных загрузки |
| STG | Приведение типов, очистка и удаление дубликатов |
| DDS | Формирование фактов и измерений |
| DM | Подготовка агрегированных витрин для аналитики |

Оркестрация выполняется в Airflow. Основной оркестрируемый путь использует dbt-модели для STG и DDS, Python и SQL для ODS, SQL и `psql` для DM. Каталог `sql/` дополнительно сохраняет самостоятельную SQL-реализацию слоёв, которая использовалась командой при разработке и проверке преобразований.

## Структура репозитория

```text
dags/           Airflow DAG-и для слоёв ODS, STG, DDS и DM
dbt/            dbt-проект с моделями STG и DDS
python/         загрузчики данных и команды локального запуска
sql/            SQL-скрипты по слоям хранилища
scripts/        вспомогательные команды Git
config.example.env
requirements.txt
```

## Источники данных

- архивы рейсов в формате CSV.GZ, размещённые в S3-совместимом Object Storage;
- справочник аэропортов [OurAirports](https://ourairports.com/data/).

ODS сохраняет имя источника, номер строки, идентификатор загрузки и время обработки. Ограничение по паре `source + row_number` предотвращает повторную вставку одной строки.

## Подготовка окружения

Для запуска Python-скриптов требуется Python 3.9 или новее.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp config.example.env config.env
```

В `config.env` необходимо указать параметры PostgreSQL и Object Storage. Файл содержит секреты и исключён из Git.

Основные переменные:

| Переменная | Назначение |
|------------|------------|
| `PG_HOST`, `PG_PORT`, `PG_DATABASE` | Подключение к PostgreSQL |
| `PG_USER`, `PG_PASSWORD` | Учётные данные PostgreSQL |
| `S3_ENDPOINT_URL` | Адрес S3-совместимого хранилища |
| `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | Учётные данные Object Storage |
| `S3_SOURCE_BUCKET` | Bucket с исходными файлами рейсов |
| `S3_AIRFLOW_BUCKET` | Bucket для файлов Airflow |

## Локальный запуск

Слои выполняются последовательно:

```bash
python python/ods/run_ods_pipeline.py
python python/stg/run_stg_pipeline.py
python python/dds/run_dds_pipeline.py
```

ODS загружает справочник аэропортов, определяет новые архивы рейсов в Object Storage и записывает результат каждой загрузки в `team_tro_sam_ser_pas_etl.load_control`.

## dbt

Файл `dbt/dbt_project.yml` позволяет запускать модели как самостоятельный dbt-проект. В локальном `profiles.yml` должен быть настроен профиль `team_tro_sam_ser_pas` для PostgreSQL.

```bash
cd dbt
dbt debug
dbt run --select path:models/evserenko
dbt run --select path:models/mvtrofimov
```

Макрос `generate_schema_name` сохраняет имена схем, указанные в моделях, без добавления схемы из профиля.

## Airflow

DAG-и запускаются в следующем порядке:

```text
dipaschenko_ods_pipeline_dag
evserenko_stg_pipeline_dag
mvtrofimov_dds_pipeline_dag
dasamundzhyan_dm_pipeline_dag
```

Файлы проекта загружаются в Object Storage командой:

```bash
python python/s3/s3_push_AF.py
```

`config.env` не загружается этим скриптом. Переменные окружения и секреты необходимо настроить отдельно в среде Airflow.

Скрипт поддерживает структуру учебного Object Storage: полный проект загружается под `S3_TEAM_PREFIX`, dbt также публикуется в корне bucket, а файлы DAG - в корне каталога DAG Airflow. Поэтому DAG-и проверяют несколько ожидаемых путей. Для другой установки достаточно сохранить один из этих вариантов или заменить пути на расположение проекта в своей среде.

## Модель DDS

Измерения:

- `dim_date` - календарные атрибуты даты;
- `dim_carrier` - авиаперевозчики;
- `dim_airport` - аэропорты и географические атрибуты;
- `dim_aircraft` - воздушные суда по бортовому номеру.

Факты:

- `fct_flights` - выполненные рейсы и показатели задержек;
- `fct_cancelled_flights` - отменённые рейсы и причины отмены.

Для локального времени рейсов используется часовой пояс региона аэропорта. Если регион не распознан, применяется UTC.

## Витрины DM

- `flight_overview` содержит количество рейсов, процент отмен и показатели задержек по датам, перевозчикам и аэропортам;
- `delay_reasons` содержит длительность и долю задержек по каждой причине.

Запросы для проверки витрин находятся в `sql/dm/004_check_dm_metrics.sql`. Примеры запросов для графиков DataLens находятся в `sql/dm/005_datalens_chart_queries.sql`.

## Командная работа

Разработка была разделена по слоям:

- Dmitri - ODS и загрузка данных;
- Elena - STG;
- Matvey - DDS;
- Dina - DM и аналитические витрины.

История Git сохраняет авторство участников проекта.

## Ограничения

- исходные файлы рейсов не включены в репозиторий из-за их объёма;
- для полного запуска необходимы PostgreSQL, Object Storage, Airflow и локальный профиль dbt;
- интеграционная проверка всех слоёв требует доступа к учебной инфраструктуре;
- Airflow DAG-и используют пути, принятые в учебном окружении.
