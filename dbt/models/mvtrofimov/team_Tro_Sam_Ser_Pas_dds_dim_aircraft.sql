{{ config(
    materialized='table',
    schema='team_tro_sam_ser_pas_dds'
) }}

select
    row_number() over (order by tail_num) as aircraft_sk,
    tail_num
from (
    select distinct tail_num
    from {{ ref('team_Tro_Sam_Ser_Pas_stg_flights_deduplicated') }}
    where tail_num is not null
) aircrafts
