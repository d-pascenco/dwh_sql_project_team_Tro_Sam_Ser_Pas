DROP TABLE IF EXISTS team_tro_sam_ser_pas_dm.delay_reasons;

CREATE TABLE team_tro_sam_ser_pas_dm.delay_reasons AS
WITH delay_reasons AS (
    SELECT
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code,
        'Carrier delay' AS delay_reason,
        1 AS delay_reason_order,
        SUM(carrier_delay_min) AS delay_min
    FROM team_tro_sam_ser_pas_dm.flight_overview
    GROUP BY
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code

    UNION ALL

    SELECT
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code,
        'Weather delay' AS delay_reason,
        2 AS delay_reason_order,
        SUM(weather_delay_min) AS delay_min
    FROM team_tro_sam_ser_pas_dm.flight_overview
    GROUP BY
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code

    UNION ALL

    SELECT
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code,
        'NAS delay' AS delay_reason,
        3 AS delay_reason_order,
        SUM(nas_delay_min) AS delay_min
    FROM team_tro_sam_ser_pas_dm.flight_overview
    GROUP BY
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code

    UNION ALL

    SELECT
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code,
        'Security delay' AS delay_reason,
        4 AS delay_reason_order,
        SUM(security_delay_min) AS delay_min
    FROM team_tro_sam_ser_pas_dm.flight_overview
    GROUP BY
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code

    UNION ALL

    SELECT
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code,
        'Late aircraft delay' AS delay_reason,
        5 AS delay_reason_order,
        SUM(late_aircraft_min) AS delay_min
    FROM team_tro_sam_ser_pas_dm.flight_overview
    GROUP BY
        flight_dt,
        year_num,
        quarter_num,
        month_num,
        month_name,
        carrier_code
)

SELECT
    flight_dt,
    year_num,
    quarter_num,
    month_num,
    month_name,
    carrier_code,
    delay_reason,
    delay_reason_order,
    delay_min,

    ROUND(
        delay_min::NUMERIC
        / NULLIF(SUM(delay_min) OVER (
            PARTITION BY flight_dt, carrier_code
        ), 0)
        * 100,
        2
    ) AS delay_reason_pct,

    CURRENT_TIMESTAMP AS processed_dttm
FROM delay_reasons
WHERE delay_min > 0;