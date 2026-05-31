# DWH Проект

## Цель

Разработка хранилища данных для анализа авиаперелётов США.

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

## Секреты

Для локальных настроек используется файл:

```text
config.env
```

Подтянуть актуальную версию из гитхаб:

```
./scripts/git_pull.sh
```

Запушить свои наработки:

```
./scripts/git_push.sh "название коммита своё"
```

После первого подтягивания репозитория из гитхаб, нужно дать права на запуск скриптов:
```
cd /home/jovyan/work/dwh_sql_project_team_Tro_Sam_Ser_Pas
chmod +x scripts/git_push.sh
chmod +x scripts/git_pull.sh
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