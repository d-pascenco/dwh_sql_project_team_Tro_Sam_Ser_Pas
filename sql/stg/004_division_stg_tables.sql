-- разделение на отмененные и выполненные рейсы
create or replace view team_tro_sam_ser_pas_stg.flights_success_raw as
select *
from team_tro_sam_ser_pas_stg.flights_clean
where cancelled = 0;

create or replace view team_tro_sam_ser_pas_stg.flights_cancelled_raw as
select *
from team_tro_sam_ser_pas_stg.flights_clean
where cancelled = 1;