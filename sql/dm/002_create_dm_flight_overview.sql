DROP TABLE IF EXISTS team_tro_sam_ser_pas_dm.flight_overview;

CREATE TABLE team_tro_sam_ser_pas_dm.flight_overview AS
WITH completed_flights AS (
    SELECT
        date_sk,
        carrier_sk,
        origin_airport_sk,
        dest_airport_sk,

        COUNT(*) AS completed_flights_cnt,
        AVG(dep_delay_min) AS avg_dep_delay_min,
        AVG(arr_delay_min) AS avg_arr_delay_min,
        SUM(COALESCE(dep_delay_min, 0)) AS dep_delay_total_min,
        SUM(COALESCE(arr_delay_min, 0)) AS arr_delay_total_min,
        SUM(distance_m) AS total_distance_m,

        SUM(COALESCE(carrier_delay_min, 0)) AS carrier_delay_min,
        SUM(COALESCE(weather_delay_min, 0)) AS weather_delay_min,
        SUM(COALESCE(nas_delay_min, 0)) AS nas_delay_min,
        SUM(COALESCE(security_delay_min, 0)) AS security_delay_min,
        SUM(COALESCE(late_aircraft_min, 0)) AS late_aircraft_min
    FROM team_tro_sam_ser_pas_dds."team_Tro_Sam_Ser_Pas_dds_fct_flights"
    GROUP BY
        date_sk,
        carrier_sk,
        origin_airport_sk,
        dest_airport_sk
),

cancelled_flights AS (
    SELECT
        date_sk,
        carrier_sk,
        origin_airport_sk,
        dest_airport_sk,

        COUNT(*) AS cancelled_flights_cnt
    FROM team_tro_sam_ser_pas_dds."team_Tro_Sam_Ser_Pas_dds_fct_cancelled_flights"
    GROUP BY
        date_sk,
        carrier_sk,
        origin_airport_sk,
        dest_airport_sk
),

flights_base AS (
    SELECT
        COALESCE(cf.date_sk, cnf.date_sk) AS date_sk,
        COALESCE(cf.carrier_sk, cnf.carrier_sk) AS carrier_sk,
        COALESCE(cf.origin_airport_sk, cnf.origin_airport_sk) AS origin_airport_sk,
        COALESCE(cf.dest_airport_sk, cnf.dest_airport_sk) AS dest_airport_sk,

        COALESCE(cf.completed_flights_cnt, 0) AS completed_flights_cnt,
        COALESCE(cnf.cancelled_flights_cnt, 0) AS cancelled_flights_cnt,

        cf.avg_dep_delay_min,
        cf.avg_arr_delay_min,
        COALESCE(cf.dep_delay_total_min, 0) AS dep_delay_total_min,
        COALESCE(cf.arr_delay_total_min, 0) AS arr_delay_total_min,

        COALESCE(cf.total_distance_m, 0) AS total_distance_m,

        COALESCE(cf.carrier_delay_min, 0) AS carrier_delay_min,
        COALESCE(cf.weather_delay_min, 0) AS weather_delay_min,
        COALESCE(cf.nas_delay_min, 0) AS nas_delay_min,
        COALESCE(cf.security_delay_min, 0) AS security_delay_min,
        COALESCE(cf.late_aircraft_min, 0) AS late_aircraft_min
    FROM completed_flights cf
    FULL JOIN cancelled_flights cnf
        ON cf.date_sk = cnf.date_sk
        AND cf.carrier_sk = cnf.carrier_sk
        AND cf.origin_airport_sk = cnf.origin_airport_sk
        AND cf.dest_airport_sk = cnf.dest_airport_sk
)

SELECT
    d.flight_dt,
    d.year_num,
    d.quarter_num,
    d.month_num,
    d.month_name,
    d.day_num,
    d.day_name,
    d.is_weekend,

    c.carrier_code,

    oa.iata_code AS origin_airport_code,
    oa.airport_name AS origin_airport_name,
    oa.municipality AS origin_city,
    oa.iso_region AS origin_region,

    da.iata_code AS dest_airport_code,
    da.airport_name AS dest_airport_name,
    da.municipality AS dest_city,
    da.iso_region AS dest_region,

    b.completed_flights_cnt,
    b.cancelled_flights_cnt,
    b.completed_flights_cnt + b.cancelled_flights_cnt AS total_flights_cnt,

    ROUND(
        b.cancelled_flights_cnt::NUMERIC
        / NULLIF(b.completed_flights_cnt + b.cancelled_flights_cnt, 0)
        * 100,
        2
    ) AS cancellation_pct,

    ROUND(b.avg_dep_delay_min, 2) AS avg_dep_delay_min,
    ROUND(b.avg_arr_delay_min, 2) AS avg_arr_delay_min,
    b.dep_delay_total_min,
    b.arr_delay_total_min,

    b.total_distance_m,

    b.carrier_delay_min,
    b.weather_delay_min,
    b.nas_delay_min,
    b.security_delay_min,
    b.late_aircraft_min,

    CURRENT_TIMESTAMP AS processed_dttm
FROM flights_base b
JOIN team_tro_sam_ser_pas_dds."team_Tro_Sam_Ser_Pas_dds_dim_date" d
    ON b.date_sk = d.date_sk
JOIN team_tro_sam_ser_pas_dds."team_Tro_Sam_Ser_Pas_dds_dim_carrier" c
    ON b.carrier_sk = c.carrier_sk
JOIN team_tro_sam_ser_pas_dds."team_Tro_Sam_Ser_Pas_dds_dim_airport" oa
    ON b.origin_airport_sk = oa.airport_sk
JOIN team_tro_sam_ser_pas_dds."team_Tro_Sam_Ser_Pas_dds_dim_airport" da
    ON b.dest_airport_sk = da.airport_sk;