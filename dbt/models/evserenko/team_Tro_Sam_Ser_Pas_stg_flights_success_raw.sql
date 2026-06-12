{{ config(
    materialized='view',
    schema='team_tro_sam_ser_pas_stg'
) }}

select *
from {{ ref('team_Tro_Sam_Ser_Pas_stg_flights_deduplicated') }}
where cancelled = 0
