{{ config(
    materialized='view',
    schema='team_tro_sam_ser_pas_stg'
) }}

with dup_airports as (
    select
        *,
        row_number() over (
            partition by iata_code
            order by
                batch_id desc,
                processed_dttm desc,
                airport_id desc,
                source desc,
                row_number desc
        ) as duplicate
    from {{ ref('team_Tro_Sam_Ser_Pas_stg_airports_clean') }}
    where iata_code is not null
)

select *
from dup_airports
where duplicate = 1