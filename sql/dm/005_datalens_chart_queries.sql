SELECT
    flight_dt,
    SUM(completed_flights_cnt) AS completed_flights_cnt,
    SUM(cancelled_flights_cnt) AS cancelled_flights_cnt,
    SUM(total_flights_cnt) AS total_flights_cnt
FROM team_tro_sam_ser_pas_dm.flight_overview
GROUP BY flight_dt
ORDER BY flight_dt;


SELECT
    carrier_code,
    SUM(cancelled_flights_cnt) AS cancelled_flights_cnt,
    SUM(total_flights_cnt) AS total_flights_cnt,
    ROUND(
        SUM(cancelled_flights_cnt)::NUMERIC
        / NULLIF(SUM(total_flights_cnt), 0)
        * 100,
        2
    ) AS cancellation_pct
FROM team_tro_sam_ser_pas_dm.flight_overview
GROUP BY carrier_code
HAVING SUM(total_flights_cnt) >= 1000
ORDER BY cancellation_pct DESC
LIMIT 15;


SELECT
    carrier_code,
    SUM(completed_flights_cnt) AS completed_flights_cnt,
    ROUND(
        SUM(dep_delay_total_min)::NUMERIC
        / NULLIF(SUM(completed_flights_cnt), 0),
        2
    ) AS avg_dep_delay_min,
    ROUND(
        SUM(arr_delay_total_min)::NUMERIC
        / NULLIF(SUM(completed_flights_cnt), 0),
        2
    ) AS avg_arr_delay_min
FROM team_tro_sam_ser_pas_dm.flight_overview
GROUP BY carrier_code
HAVING SUM(completed_flights_cnt) >= 1000
ORDER BY avg_dep_delay_min DESC
LIMIT 15;


SELECT
    delay_reason,
    SUM(delay_min) AS total_delay_min,
    ROUND(
        SUM(delay_min)::NUMERIC
        / NULLIF(SUM(SUM(delay_min)) OVER (), 0)
        * 100,
        2
    ) AS delay_reason_pct
FROM team_tro_sam_ser_pas_dm.delay_reasons
GROUP BY
    delay_reason,
    delay_reason_order
ORDER BY delay_reason_order;


SELECT
    origin_airport_code,
    origin_city,
    SUM(completed_flights_cnt) AS completed_flights_cnt,
    ROUND(
        SUM(dep_delay_total_min)::NUMERIC
        / NULLIF(SUM(completed_flights_cnt), 0),
        2
    ) AS avg_dep_delay_min
FROM team_tro_sam_ser_pas_dm.flight_overview
GROUP BY
    origin_airport_code,
    origin_city
HAVING SUM(completed_flights_cnt) >= 1000
ORDER BY avg_dep_delay_min DESC
LIMIT 15;
