{{ config(
    materialized='table',
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
    case
        when f.scheduled_dep_tm is null then null
        else (
            f.flight_dt::timestamp
            + make_interval(hours => f.scheduled_dep_tm / 100, mins => f.scheduled_dep_tm % 100)
        ) at time zone (
            case
                when origin_airport.iso_region in ('US-CT', 'US-DC', 'US-DE', 'US-FL', 'US-GA', 'US-MA', 'US-MD', 'US-ME', 'US-MI', 'US-NC', 'US-NH', 'US-NJ', 'US-NY', 'US-OH', 'US-PA', 'US-RI', 'US-SC', 'US-VA', 'US-VT', 'US-WV') then 'America/New_York'
                when origin_airport.iso_region in ('US-AL', 'US-AR', 'US-IA', 'US-IL', 'US-IN', 'US-KS', 'US-KY', 'US-LA', 'US-MN', 'US-MO', 'US-MS', 'US-ND', 'US-NE', 'US-OK', 'US-SD', 'US-TN', 'US-TX', 'US-WI') then 'America/Chicago'
                when origin_airport.iso_region in ('US-AZ', 'US-CO', 'US-ID', 'US-MT', 'US-NM', 'US-UT', 'US-WY') then 'America/Denver'
                when origin_airport.iso_region in ('US-CA', 'US-NV', 'US-OR', 'US-WA') then 'America/Los_Angeles'
                when origin_airport.iso_region = 'US-AK' then 'America/Anchorage'
                when origin_airport.iso_region = 'US-HI' then 'Pacific/Honolulu'
                else 'UTC'
            end
        )
    end as sched_dttm_local,
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
