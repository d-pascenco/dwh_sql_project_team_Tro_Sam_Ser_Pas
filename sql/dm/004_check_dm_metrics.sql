SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'team_tro_sam_ser_pas_dm'
ORDER BY table_name;


SELECT
    COUNT(*) AS rows_cnt,
    SUM(completed_flights_cnt) AS completed_flights_cnt,
    SUM(cancelled_flights_cnt) AS cancelled_flights_cnt,
    SUM(total_flights_cnt) AS total_flights_cnt,
    ROUND(
        SUM(cancelled_flights_cnt)::NUMERIC
        / NULLIF(SUM(total_flights_cnt), 0)
        * 100,
        2
    ) AS cancellation_pct,
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
FROM team_tro_sam_ser_pas_dm.flight_overview;


SELECT
    delay_reason,
    SUM(delay_min) AS total_delay_min,
    ROUND(AVG(delay_reason_pct), 2) AS avg_delay_reason_pct
FROM team_tro_sam_ser_pas_dm.delay_reasons
GROUP BY
    delay_reason,
    delay_reason_order
ORDER BY delay_reason_order;