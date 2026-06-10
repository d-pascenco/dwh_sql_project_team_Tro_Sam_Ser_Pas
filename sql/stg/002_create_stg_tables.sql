create table if not exists team_tro_sam_ser_pas_stg.flights_clean (
    source text not null,                                           -- имя файла, откуда пришла строка
    row_number bigint not null,                                     -- номер строки внутри исходного файла
       
    flight_dt date,                                                 -- дата рейса
    carrier_code text,                                              -- код авиаперевозчика
    carrier_flight_num text,                                        -- номер рейса у перевозчика
    tail_num text,                                                  -- бортовой номер самолета
    origin_code text,                                               -- аэропорт вылета
    dest_code text,                                                 -- аэропорт прилета
    scheduled_dep_tm integer,                                       -- запланированное время вылета
    actual_dep_tm integer,                                          -- фактическое время вылета
    scheduled_arr_tm integer,                                       -- запланированное время прибытия
    actual_arr_tm integer,                                          -- фактическое время прибытия
    dep_delay_min numeric,                                          -- задержка вылета в минутах
    arr_delay_min numeric,                                          -- задержка прибытия в минутах
    cancelled integer,                                              -- флаг отмены рейса: 0 - выполнен, 1 - отменен
    cancellation_code text,                                         -- код причины отмены рейса
    distance_m numeric,                                             -- расстояние рейса в милях
    carrier_delay_min numeric,                                      -- задержка по вине перевозчика
    weather_delay_min numeric,                                      -- задержка из-за погоды
    nas_delay_min numeric,                                          -- задержка из-за NAS
    security_delay_min numeric,                                     -- задержка из-за проверки безопасности
    late_aircraft_min numeric,                                      -- задержка из-за позднего прибытия самолета

    processed_dttm timestamp not null,                              -- дата и время обработки записи
    batch_id bigint not null,                                       -- номер батча загрузки

    constraint uq_flights_clean_source_row unique (source, row_number) -- уникальность строки из исходного файла на всякий случай :)
);


create table if not exists team_tro_sam_ser_pas_stg.airports_clean (
    source text not null,                                           -- источник строки
    row_number bigint not null,                                     -- номер строки в исходном файле

    airport_id bigint,                                              -- внутренний идентификатор аэропорта
    ident text,                                                     -- идентификатор аэропорта
    airport_name text,                                              -- название аэропорта
    airport_type text,                                              -- тип аэропорта
    gps_code text,                                                  -- GPS код аэропорта
    iata_code text,                                                 -- IATA код аэропорта
    icao_code text,                                                 -- ICAO код аэропорта
    local_code text,                                                -- локальный код аэропорта
    continent text,                                                 -- континент
    iso_country text,                                               -- страна
    iso_region text,                                                -- регион
    municipality text,                                              -- город
    latitude_deg numeric,                                           -- широта
    longitude_deg numeric,                                          -- долгота
    elevation_ft integer,                                           -- высота над уровнем моря в футах
    scheduled_service text,                                         -- есть ли регулярные рейсы
    home_link text,                                                 -- сайт аэропорта
    wikipedia_link text,                                            -- ссылка на Wikipedia
    keywords text,                                                  -- ключевые слова

    processed_dttm timestamp not null,                              -- дата обработки
    batch_id bigint not null,                                       -- номер загрузки

    constraint uq_airports_clean_source_row unique (source, row_number) -- уникальность строки из исходного файла на всякий случай :)
);