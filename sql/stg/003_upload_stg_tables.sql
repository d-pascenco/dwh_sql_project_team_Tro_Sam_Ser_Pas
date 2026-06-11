--распарсим json

insert into team_tro_sam_ser_pas_stg.flights_clean ( 
    source,
    row_number,
    flight_dt,
    carrier_code,
    carrier_flight_num,
    tail_num,
    origin_code,
    dest_code,
    scheduled_dep_tm,
    actual_dep_tm,
    scheduled_arr_tm,
    actual_arr_tm,
    dep_delay_min,
    arr_delay_min,
    cancelled,
    cancellation_code,
    distance_m,
    carrier_delay_min,
    weather_delay_min,
    nas_delay_min,
    security_delay_min,
    late_aircraft_min,
    processed_dttm,
    batch_id
)
select
    source,
    row_number,

    nullif(data ->> 'FlightDate', '')::date as flight_dt, --nullif для замены пустой стоки на null 
    upper(trim(data ->> 'Reporting_Airline')) as carrier_code, -- upper - приведем к верхнему регистру, trim - уберем лишние проблемы
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
where upload_id > ( --обновление только по новым батчам 
        select coalesce(max(batch_id), 0)
        from team_tro_sam_ser_pas_stg.flights_clean
    )
on conflict (source, row_number) do update set --при случайном запуске во второй раз, чтобы ничего не упало и не создались дубли
    flight_dt = excluded.flight_dt,
    carrier_code = excluded.carrier_code,
    carrier_flight_num = excluded.carrier_flight_num,
    tail_num = excluded.tail_num,
    origin_code = excluded.origin_code,
    dest_code = excluded.dest_code,
    scheduled_dep_tm = excluded.scheduled_dep_tm,
    actual_dep_tm = excluded.actual_dep_tm,
    scheduled_arr_tm = excluded.scheduled_arr_tm,
    actual_arr_tm = excluded.actual_arr_tm,
    dep_delay_min = excluded.dep_delay_min,
    arr_delay_min = excluded.arr_delay_min,
    cancelled = excluded.cancelled,
    cancellation_code = excluded.cancellation_code,
    distance_m = excluded.distance_m,
    carrier_delay_min = excluded.carrier_delay_min,
    weather_delay_min = excluded.weather_delay_min,
    nas_delay_min = excluded.nas_delay_min,
    security_delay_min = excluded.security_delay_min,
    late_aircraft_min = excluded.late_aircraft_min,
    processed_dttm = excluded.processed_dttm,
    batch_id = excluded.batch_id;



insert into team_tro_sam_ser_pas_stg.airports_clean (
    source,
    row_number,
    airport_id,
    ident,
    airport_name,
    airport_type,
    gps_code,
    iata_code,
    icao_code,
    local_code,
    continent,
    iso_country,
    iso_region,
    municipality,
    latitude_deg,
    longitude_deg,
    elevation_ft,
    scheduled_service,
    home_link,
    wikipedia_link,
    keywords,
    processed_dttm,
    batch_id
)
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
where upload_id > ( --обновление только по новым батчам 
    select coalesce(max(batch_id), 0)
    from team_tro_sam_ser_pas_stg.airports_clean
)
on conflict (source, row_number) do update set --при случайном запуске во второй раз, чтобы ничего не упало и не создались дубли
    airport_id = excluded.airport_id,
    ident = excluded.ident,
    airport_name = excluded.airport_name,
    airport_type = excluded.airport_type,
    gps_code = excluded.gps_code,
    iata_code = excluded.iata_code,
    icao_code = excluded.icao_code,
    local_code = excluded.local_code,
    continent = excluded.continent,
    iso_country = excluded.iso_country,
    iso_region = excluded.iso_region,
    municipality = excluded.municipality,
    latitude_deg = excluded.latitude_deg,
    longitude_deg = excluded.longitude_deg,
    elevation_ft = excluded.elevation_ft,
    scheduled_service = excluded.scheduled_service,
    home_link = excluded.home_link,
    wikipedia_link = excluded.wikipedia_link,
    keywords = excluded.keywords,
    processed_dttm = excluded.processed_dttm,
    batch_id = excluded.batch_id;
