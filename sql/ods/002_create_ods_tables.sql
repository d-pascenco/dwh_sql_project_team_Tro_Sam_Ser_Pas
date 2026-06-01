create table if not exists team_tro_sam_ser_pas_ods.flights_raw (
    source text not null,                                          -- имя файла откуда данные (тут будет например flights_us_data/2024-01-01/flights.csv.gz)
    row_number bigint not null,                                    -- номер строки внутри этого файла
    data jsonb not null,                                           -- основные данные (строка) в формате json
    upload_time timestamp not null default now(),                  -- дата и время загрузки строки в базу
    upload_id bigint not null                                      -- номер батча загрузки, чтобы различать
);

create table if not exists team_tro_sam_ser_pas_ods.airports_raw (
    source text not null,
    row_number bigint not null,
    data jsonb not null,
    upload_time timestamp not null default now(),
    upload_id bigint not null
);