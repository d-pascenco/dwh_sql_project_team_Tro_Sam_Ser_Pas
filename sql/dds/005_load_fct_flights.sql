-- полная перезагрузка фактов выполненных рейсов из STG
truncate table team_tro_sam_ser_pas_dds.fct_flights;

insert into team_tro_sam_ser_pas_dds.fct_flights (
    date_sk,
    carrier_sk,
    origin_airport_sk,
    dest_airport_sk,
    aircraft_sk,
    carrier_flight_num,
    scheduled_dep_tm,
    flight_dttm_local,
    scheduled_dep_dttm_local,
    actual_dep_dttm_local,
    actual_dep_tm,
    scheduled_arr_tm,
    scheduled_arr_dttm_local,
    actual_arr_tm,
    dep_delay_min,
    arr_delay_min,
    distance_m,
    carrier_delay_min,
    weather_delay_min,
    nas_delay_min,
    security_delay_min,
    late_aircraft_min,
    source,
    row_number,
    batch_id,
    processed_dttm
)
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
    end as flight_dttm_local,
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
    end as scheduled_dep_dttm_local,
    case
        when f.scheduled_dep_tm is null then null
        else (
            f.flight_dt::timestamp
            + make_interval(hours => f.scheduled_dep_tm / 100, mins => f.scheduled_dep_tm % 100)
            + make_interval(mins => coalesce(f.dep_delay_min, 0)::integer)
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
    end as actual_dep_dttm_local,
    f.actual_dep_tm,
    f.scheduled_arr_tm,
    case
        when f.scheduled_arr_tm is null then null
        else (
            f.flight_dt::timestamp
            + make_interval(hours => f.scheduled_arr_tm / 100, mins => f.scheduled_arr_tm % 100)
        ) at time zone (
            case
                when dest_airport.iso_region in ('US-CT', 'US-DC', 'US-DE', 'US-FL', 'US-GA', 'US-MA', 'US-MD', 'US-ME', 'US-MI', 'US-NC', 'US-NH', 'US-NJ', 'US-NY', 'US-OH', 'US-PA', 'US-RI', 'US-SC', 'US-VA', 'US-VT', 'US-WV') then 'America/New_York'
                when dest_airport.iso_region in ('US-AL', 'US-AR', 'US-IA', 'US-IL', 'US-IN', 'US-KS', 'US-KY', 'US-LA', 'US-MN', 'US-MO', 'US-MS', 'US-ND', 'US-NE', 'US-OK', 'US-SD', 'US-TN', 'US-TX', 'US-WI') then 'America/Chicago'
                when dest_airport.iso_region in ('US-AZ', 'US-CO', 'US-ID', 'US-MT', 'US-NM', 'US-UT', 'US-WY') then 'America/Denver'
                when dest_airport.iso_region in ('US-CA', 'US-NV', 'US-OR', 'US-WA') then 'America/Los_Angeles'
                when dest_airport.iso_region = 'US-AK' then 'America/Anchorage'
                when dest_airport.iso_region = 'US-HI' then 'Pacific/Honolulu'
                else 'UTC'
            end
        )
    end as scheduled_arr_dttm_local,
    f.actual_arr_tm,
    f.dep_delay_min,
    f.arr_delay_min,
    f.distance_m,
    f.carrier_delay_min,
    f.weather_delay_min,
    f.nas_delay_min,
    f.security_delay_min,
    f.late_aircraft_min,
    f.source,
    f.row_number,
    f.batch_id,
    f.processed_dttm
from team_tro_sam_ser_pas_stg.flights_success_raw f
join team_tro_sam_ser_pas_dds.dim_date d
    on f.flight_dt = d.flight_dt
join team_tro_sam_ser_pas_dds.dim_carrier c
    on f.carrier_code = c.carrier_code
join team_tro_sam_ser_pas_dds.dim_airport origin_airport
    on f.origin_code = origin_airport.iata_code
join team_tro_sam_ser_pas_dds.dim_airport dest_airport
    on f.dest_code = dest_airport.iata_code
left join team_tro_sam_ser_pas_dds.dim_aircraft aircraft
    on f.tail_num = aircraft.tail_num
where f.flight_dt is not null
  and f.carrier_code is not null
  and f.origin_code is not null
  and f.dest_code is not null;
