{{ config(
    materialized='view',
    schema='team_tro_sam_ser_pas_stg'
) }}

select *
from {{ ref('stg_flights_deduplicated') }}
where cancelled = 1