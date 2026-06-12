{{ config(
    materialized='table',
    schema='team_tro_sam_ser_pas_dds'
) }}

select distinct
    to_char(flight_dt, 'YYYYMMDD')::integer as date_sk,
    flight_dt,
    extract(year from flight_dt)::smallint as year_num,
    extract(quarter from flight_dt)::smallint as quarter_num,
    extract(month from flight_dt)::smallint as month_num,
    extract(day from flight_dt)::smallint as day_num,
    extract(dow from flight_dt)::smallint as day_of_week_num,
    trim(to_char(flight_dt, 'TMDay')) as day_name,
    trim(to_char(flight_dt, 'TMMonth')) as month_name,
    extract(dow from flight_dt) in (0, 6) as is_weekend
from {{ ref('team_Tro_Sam_Ser_Pas_stg_flights_deduplicated') }}
where flight_dt is not null
