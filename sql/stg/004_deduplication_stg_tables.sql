/*
Дедупликация таблицы с полетами
Дедупликацию лучше сделать перед разделением таблицы с рейсами на две: с отмененными и успешными рейсами, 
таким образом, мы сделаем дедупликацию всего для двух таблиц вместо трех.

Уникальность source+row_number не является дедупликацией рейсов, так как это только защита от повторной 
вставки одной и той же строки из одного и того же файла.
В нашем случае оптимальным будет сделать: если совпали дата, авиакомпания, номер рейса, аэропорт вылета, 
аэропорт прилёта и плановое время вылета, то считаем, что это один и тот же рейс. Если таких строк несколько, 
оставляем самую свежую по batch_id и processed_dttm. То есть для дедупликации выбираем поля: flight_dt,
carrier_code, carrier_flight_num, origin_code, dest_code, scheduled_dep_tm
*/
create or replace view team_tro_sam_ser_pas_stg.flights_deduplicated as --создаем или заменяем представление, чтобы не создавать новую таблицу
with dup_flights as (
    select
        *,
        row_number() over ( --считаем количество дубликатов
            partition by
                flight_dt,
                carrier_code,
                carrier_flight_num,
                origin_code,
                dest_code,
                scheduled_dep_tm
            order by
                batch_id desc,
                processed_dttm desc,
                source desc,
                row_number desc
        ) as duplicate
    from team_tro_sam_ser_pas_stg.flights_clean
)
select *
from dup_flights
where duplicate = 1; --берем первое вхождение, то есть остальные дубликаты отсеиваются, остается самая последняя версия

--Дедупликация выполнена через row_number() по ключу рейса. После проверки дублей по этому ключу 
--повторов не обнаружили, количество строк до и после дедупликации совпадает.

/*
Дедупликация таблицы с аэропортами
Уникальность source+row_number не является дедупликацией аэропортов, так как это только защита от повторной 
вставки одной и той же строки из одного и того же файла.
В нашем случае оптимальным будет сделать: если совпали , то считаем, что это один и тот же аэропорт. Если таких строк несколько, 
оставляем самую свежую по batch_id и processed_dttm. То есть для дедупликации выбираем поля: 
*/
create or replace view team_tro_sam_ser_pas_stg.airports_deduplicated as
with dup_airports as (
    select
        *,
        row_number() over (
            partition by iata_code
            order by
                batch_id desc,
                processed_dttm desc,
                airport_id desc,
                source desc,
                row_number desc
        ) as duplicate
    from team_tro_sam_ser_pas_stg.airports_clean
    where iata_code is not null --дедуплицируем только аэропорты, которые можно связать с рейсами по IATA-коду
)
select *
from dup_airports
where duplicate = 1;

--Дедупликация выполнена через row_number() по ключу iata_code. После проверки дублей по этому ключу 
--удалили 76488 повторов.