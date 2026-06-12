create table if not exists team_tro_sam_ser_pas_dds.dim_date (
    date_sk integer primary key,                                    -- суррогатный ключ даты (YYYYMMDD)
    flight_dt date not null unique,                                 -- календарная дата рейса
    year_num smallint not null,                                     -- год
    quarter_num smallint not null,                                  -- квартал
    month_num smallint not null,                                    -- месяц
    day_num smallint not null,                                      -- день месяца
    day_of_week_num smallint not null,                              -- день недели (0 = воскресенье)
    day_name text not null,                                         -- название дня недели
    month_name text not null,                                       -- название месяца
    is_weekend boolean not null                                     -- признак выходного дня
);

create table if not exists team_tro_sam_ser_pas_dds.dim_carrier (
    carrier_sk serial primary key,                                  -- суррогатный ключ перевозчика
    carrier_code text not null unique,                              -- IATA-код авиакомпании
    carrier_name text                                               -- название (если появится в источнике)
);

create table if not exists team_tro_sam_ser_pas_dds.dim_airport (
    airport_sk serial primary key,                                  -- суррогатный ключ аэропорта
    iata_code text not null unique,                                 -- IATA-код аэропорта
    airport_id bigint,                                              -- id из справочника OurAirports
    ident text,                                                     -- идентификатор аэропорта
    airport_name text,                                              -- название аэропорта
    airport_type text,                                              -- тип аэропорта
    municipality text,                                              -- город
    iso_country text,                                               -- страна
    iso_region text,                                                -- регион
    continent text,                                                 -- континент
    latitude_deg numeric,                                           -- широта
    longitude_deg numeric,                                          -- долгота
    elevation_ft integer,                                           -- высота над уровнем моря
    scheduled_service text                                          -- признак регулярного обслуживания
);

create table if not exists team_tro_sam_ser_pas_dds.dim_aircraft (
    aircraft_sk serial primary key,                                 -- суррогатный ключ борта
    tail_num text not null unique                                   -- бортовой номер
);
