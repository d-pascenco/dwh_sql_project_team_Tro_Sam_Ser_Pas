{{ config(
    materialized='table',
    schema='team_tro_sam_ser_pas_dds'
) }}

select
    row_number() over (order by carrier_code) as carrier_sk,
    carrier_code
from (
    select distinct carrier_code
    from {{ ref('team_Tro_Sam_Ser_Pas_stg_flights_deduplicated') }}
    where carrier_code is not null
) carriers
