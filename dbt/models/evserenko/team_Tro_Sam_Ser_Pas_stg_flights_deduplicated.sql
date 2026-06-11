{{ config(
    materialized='view',
    schema='team_tro_sam_ser_pas_stg'
) }}

with dup_flights as (
    select
        *,
        row_number() over (
            partition by
                flight_dt,
                carrier_code,
                carrier_flight_num,
                origin_code,
                dest_code,
                scheduled_dep_tm
            order by
                batch_id desc,
                processed_dttm desc,
                source desc,
                row_number desc
        ) as duplicate
    from {{ ref('stg_flights_clean') }}
)

select *
from dup_flights
where duplicate = 1