create table if not exists team_tro_sam_ser_pas_etl.load_control (                 -- таблица чтобы контролить etl (техническая)
    flow_name text primary key,                                                    -- название etl потока
    last_success_upload timestamp,                                                 -- дата и время последней загрузки
    last_loaded_source text,                                                       -- последний загруженный путь
    last_upload_id bigint,                                                         -- последний нобер батча загрузки
    row_count_uploaded bigint,                                                     -- количество загруженных строк
    status text,                                                                   -- статус последней загрузки SUCCESS, FAILED, RUNNING
    error_text text,                                                               -- текст ошибки если загружка не прошла
    updated_dttm timestamp default now()                                           -- дата и время обновления этой записи в базе
);