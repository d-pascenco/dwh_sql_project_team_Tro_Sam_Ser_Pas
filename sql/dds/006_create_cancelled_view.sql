-- представление для отменённых рейсов с ключами измерений (для BI-слоя DM)
create or replace view team_tro_sam_ser_pas_dds.fct_cancelled_flights as
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
from team_tro_sam_ser_pas_stg.flights_cancelled_raw f
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
