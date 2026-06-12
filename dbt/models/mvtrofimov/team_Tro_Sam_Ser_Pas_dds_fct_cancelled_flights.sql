{{ config(
    materialized='view',
    schema='team_tro_sam_ser_pas_dds'
) }}

select
    d.date_sk,
    c.carrier_sk,
    origin_airport.airport_sk as origin_airport_sk,
    dest_airport.airport_sk as dest_airport_sk,
    aircraft.aircraft_sk,
    f.carrier_flight_num,
    f.scheduled_dep_tm,
    f.actual_dep_tm,
    f.scheduled_arr_tm,
    f.actual_arr_tm,
    f.dep_delay_min,
    f.arr_delay_min,
    f.distance_m,
    f.cancellation_code,
    f.source,
    f.row_number,
    f.batch_id,
    f.processed_dttm
from {{ ref('team_Tro_Sam_Ser_Pas_stg_flights_cancelled_raw') }} f
join {{ ref('team_Tro_Sam_Ser_Pas_dds_dim_date') }} d
    on f.flight_dt = d.flight_dt
join {{ ref('team_Tro_Sam_Ser_Pas_dds_dim_carrier') }} c
    on f.carrier_code = c.carrier_code
join {{ ref('team_Tro_Sam_Ser_Pas_dds_dim_airport') }} origin_airport
    on f.origin_code = origin_airport.iata_code
join {{ ref('team_Tro_Sam_Ser_Pas_dds_dim_airport') }} dest_airport
    on f.dest_code = dest_airport.iata_code
left join {{ ref('team_Tro_Sam_Ser_Pas_dds_dim_aircraft') }} aircraft
    on f.tail_num = aircraft.tail_num
where f.flight_dt is not null
  and f.carrier_code is not null
  and f.origin_code is not null
  and f.dest_code is not null
