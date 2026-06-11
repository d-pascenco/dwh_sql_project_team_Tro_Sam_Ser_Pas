{{ config(
    materialized='table',
    schema='team_tro_sam_ser_pas_stg'
) }}

select
    source,
    row_number,

    nullif(data ->> 'id', '')::bigint as airport_id,
    nullif(trim(data ->> 'ident'), '') as ident,
    nullif(trim(data ->> 'name'), '') as airport_name,
    nullif(trim(data ->> 'type'), '') as airport_type,
    nullif(trim(data ->> 'gps_code'), '') as gps_code,
    nullif(trim(data ->> 'iata_code'), '') as iata_code,
    nullif(trim(data ->> 'icao_code'), '') as icao_code,
    nullif(trim(data ->> 'local_code'), '') as local_code,
    nullif(trim(data ->> 'continent'), '') as continent,
    nullif(trim(data ->> 'iso_country'), '') as iso_country,
    nullif(trim(data ->> 'iso_region'), '') as iso_region,
    nullif(trim(data ->> 'municipality'), '') as municipality,
    nullif(data ->> 'latitude_deg', '')::numeric as latitude_deg,
    nullif(data ->> 'longitude_deg', '')::numeric as longitude_deg,
    nullif(data ->> 'elevation_ft', '')::integer as elevation_ft,
    nullif(trim(data ->> 'scheduled_service'), '') as scheduled_service,
    nullif(trim(data ->> 'home_link'), '') as home_link,
    nullif(trim(data ->> 'wikipedia_link'), '') as wikipedia_link,
    nullif(trim(data ->> 'keywords'), '') as keywords,

    upload_time as processed_dttm,
    upload_id as batch_id
from team_tro_sam_ser_pas_ods.airports_raw