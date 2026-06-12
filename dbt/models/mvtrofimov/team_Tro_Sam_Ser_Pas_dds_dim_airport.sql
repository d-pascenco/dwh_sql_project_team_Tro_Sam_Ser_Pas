{{ config(
    materialized='table',
    schema='team_tro_sam_ser_pas_dds'
) }}

with airports as (
    with reference_airports as (
        select
            upper(trim(iata_code)) as iata_code,
            airport_id,
            ident,
            airport_name,
            airport_type,
            municipality,
            iso_country,
            iso_region,
            continent,
            latitude_deg,
            longitude_deg,
            elevation_ft,
            scheduled_service
        from {{ ref('team_Tro_Sam_Ser_Pas_stg_airports_deduplicated') }}
        where iata_code is not null
    ),

    flight_airport_codes as (
        select origin_code as iata_code
        from {{ ref('team_Tro_Sam_Ser_Pas_stg_flights_deduplicated') }}
        where origin_code is not null

        union

        select dest_code as iata_code
        from {{ ref('team_Tro_Sam_Ser_Pas_stg_flights_deduplicated') }}
        where dest_code is not null
    ),

    missing_airports as (
        select
            flight_airport_codes.iata_code,
            null::bigint as airport_id,
            null::text as ident,
            'Unknown airport (' || flight_airport_codes.iata_code || ')' as airport_name,
            null::text as airport_type,
            null::text as municipality,
            null::text as iso_country,
            null::text as iso_region,
            null::text as continent,
            null::numeric as latitude_deg,
            null::numeric as longitude_deg,
            null::integer as elevation_ft,
            null::text as scheduled_service
        from flight_airport_codes
        left join reference_airports
            on flight_airport_codes.iata_code = reference_airports.iata_code
        where reference_airports.iata_code is null
    )

    select * from reference_airports
    union all
    select * from missing_airports
)

select
    row_number() over (order by iata_code) as airport_sk,
    iata_code,
    airport_id,
    ident,
    airport_name,
    airport_type,
    municipality,
    iso_country,
    iso_region,
    continent,
    latitude_deg,
    longitude_deg,
    elevation_ft,
    scheduled_service
from airports
