create table if not exists team_tro_sam_ser_pas_dds.fct_flights (
    flight_sk bigserial primary key,                                -- суррогатный ключ факта

    date_sk integer not null references team_tro_sam_ser_pas_dds.dim_date (date_sk),
    carrier_sk integer not null references team_tro_sam_ser_pas_dds.dim_carrier (carrier_sk),
    origin_airport_sk integer not null references team_tro_sam_ser_pas_dds.dim_airport (airport_sk),
    dest_airport_sk integer not null references team_tro_sam_ser_pas_dds.dim_airport (airport_sk),
    aircraft_sk integer references team_tro_sam_ser_pas_dds.dim_aircraft (aircraft_sk),

    carrier_flight_num text,                                        -- номер рейса (дегенеративное измерение)
    scheduled_dep_tm integer,                                       -- плановое время вылета (HHMM)
    flight_dttm_local timestamptz,                                  -- локальное время и дата вылета с часовым поясом
    scheduled_dep_dttm_local timestamptz,                           -- плановое локальное время вылета с часовым поясом
    actual_dep_dttm_local timestamptz,                              -- фактическое локальное время вылета: план + задержка
    actual_dep_tm integer,                                          -- фактическое время вылета
    scheduled_arr_tm integer,                                       -- плановое время прилёта
    scheduled_arr_dttm_local timestamptz,                           -- плановое локальное время прилёта с часовым поясом
    actual_arr_tm integer,                                          -- фактическое время прилёта
    dep_delay_min numeric,                                          -- задержка вылета, мин
    arr_delay_min numeric,                                          -- задержка прилёта, мин
    distance_m numeric,                                             -- расстояние, мили
    carrier_delay_min numeric,                                      -- задержка по вине перевозчика
    weather_delay_min numeric,                                      -- задержка из-за погоды
    nas_delay_min numeric,                                          -- задержка NAS
    security_delay_min numeric,                                     -- задержка безопасности
    late_aircraft_min numeric,                                      -- задержка из-за позднего борта

    source text not null,                                           -- файл-источник (lineage)
    row_number bigint not null,                                     -- номер строки в файле
    batch_id bigint not null,                                       -- id батча загрузки
    processed_dttm timestamp not null,                              -- время обработки в STG

    constraint uq_fct_flights_business_key unique (
        date_sk,
        carrier_sk,
        carrier_flight_num,
        origin_airport_sk,
        dest_airport_sk,
        scheduled_dep_tm
    )
);

alter table team_tro_sam_ser_pas_dds.fct_flights
    add column if not exists flight_dttm_local timestamptz,
    add column if not exists scheduled_dep_dttm_local timestamptz,
    add column if not exists actual_dep_dttm_local timestamptz,
    add column if not exists scheduled_arr_dttm_local timestamptz;
