-- загрузка измерения даты из STG
insert into team_tro_sam_ser_pas_dds.dim_date (
    date_sk,
    flight_dt,
    year_num,
    quarter_num,
    month_num,
    day_num,
    day_of_week_num,
    day_name,
    month_name,
    is_weekend
)
select distinct
    to_char(flight_dt, 'YYYYMMDD')::integer as date_sk,
    flight_dt,
    extract(year from flight_dt)::smallint as year_num,
    extract(quarter from flight_dt)::smallint as quarter_num,
    extract(month from flight_dt)::smallint as month_num,
    extract(day from flight_dt)::smallint as day_num,
    extract(dow from flight_dt)::smallint as day_of_week_num,
    trim(to_char(flight_dt, 'TMDay')) as day_name,
    trim(to_char(flight_dt, 'TMMonth')) as month_name,
    extract(dow from flight_dt) in (0, 6) as is_weekend
from team_tro_sam_ser_pas_stg.flights_deduplicated
where flight_dt is not null
on conflict (flight_dt) do nothing;


-- загрузка измерения перевозчиков
insert into team_tro_sam_ser_pas_dds.dim_carrier (carrier_code)
select distinct carrier_code
from team_tro_sam_ser_pas_stg.flights_deduplicated
where carrier_code is not null
on conflict (carrier_code) do nothing;


-- загрузка измерения аэропортов из справочника STG
insert into team_tro_sam_ser_pas_dds.dim_airport (
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
)
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
from team_tro_sam_ser_pas_stg.airports_deduplicated
where iata_code is not null
on conflict (iata_code) do update set
    airport_id = excluded.airport_id,
    ident = excluded.ident,
    airport_name = excluded.airport_name,
    airport_type = excluded.airport_type,
    municipality = excluded.municipality,
    iso_country = excluded.iso_country,
    iso_region = excluded.iso_region,
    continent = excluded.continent,
    latitude_deg = excluded.latitude_deg,
    longitude_deg = excluded.longitude_deg,
    elevation_ft = excluded.elevation_ft,
    scheduled_service = excluded.scheduled_service;


-- аэропорты из рейсов, которых нет в справочнике
insert into team_tro_sam_ser_pas_dds.dim_airport (iata_code, airport_name)
select distinct
    airport_code,
    'Unknown airport (' || airport_code || ')' as airport_name
from (
    select origin_code as airport_code
    from team_tro_sam_ser_pas_stg.flights_deduplicated
    where origin_code is not null

    union

    select dest_code as airport_code
    from team_tro_sam_ser_pas_stg.flights_deduplicated
    where dest_code is not null
) flight_airports
where not exists (
    select 1
    from team_tro_sam_ser_pas_dds.dim_airport existing
    where existing.iata_code = flight_airports.airport_code
)
on conflict (iata_code) do nothing;


-- загрузка измерения бортов
insert into team_tro_sam_ser_pas_dds.dim_aircraft (tail_num)
select distinct tail_num
from team_tro_sam_ser_pas_stg.flights_deduplicated
where tail_num is not null
on conflict (tail_num) do nothing;
