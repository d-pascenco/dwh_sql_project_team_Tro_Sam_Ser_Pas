{{ config(
    materialized='table',
    schema='team_tro_sam_ser_pas_stg'
) }}

select
    source,
    row_number,

    nullif(data ->> 'FlightDate', '')::date as flight_dt,
    upper(trim(data ->> 'Reporting_Airline')) as carrier_code,
    nullif(trim(data ->> 'Flight_Number_Reporting_Airline'), '') as carrier_flight_num,
    nullif(trim(data ->> 'Tail_Number'), '') as tail_num,
    upper(trim(data ->> 'Origin')) as origin_code,
    upper(trim(data ->> 'Dest')) as dest_code,
    nullif(data ->> 'CRSDepTime', '')::numeric::int as scheduled_dep_tm,
    nullif(data ->> 'DepTime', '')::numeric::int as actual_dep_tm,
    nullif(data ->> 'CRSArrTime', '')::numeric::int as scheduled_arr_tm,
    nullif(data ->> 'ArrTime', '')::numeric::int as actual_arr_tm,
    nullif(data ->> 'DepDelayMinutes', '')::numeric as dep_delay_min,
    nullif(data ->> 'ArrDelayMinutes', '')::numeric as arr_delay_min,
    nullif(data ->> 'Cancelled', '')::numeric::int as cancelled,
    nullif(trim(data ->> 'CancellationCode'), '') as cancellation_code,
    nullif(data ->> 'Distance', '')::numeric as distance_m,
    nullif(data ->> 'CarrierDelay', '')::numeric as carrier_delay_min,
    nullif(data ->> 'WeatherDelay', '')::numeric as weather_delay_min,
    nullif(data ->> 'NASDelay', '')::numeric as nas_delay_min,
    nullif(data ->> 'SecurityDelay', '')::numeric as security_delay_min,
    nullif(data ->> 'LateAircraftDelay', '')::numeric as late_aircraft_min,

    upload_time as processed_dttm,
    upload_id as batch_id
from team_tro_sam_ser_pas_ods.flights_raw
