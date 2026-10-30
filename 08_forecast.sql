USE global_retail;

-- ============================================================
-- 08_FORECAST: NEXT-YEAR GROSS MARGIN FORECAST
-- ============================================================

-- ============================================================
-- QUERY 1: HISTORICAL ANNUAL GROSS MARGIN
-- ============================================================

WITH annual_metrics AS (
    SELECT
        s.`year` AS fiscal_year,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE
        s.unit_price IS NOT NULL
        AND s.`year` IN (2023, 2024, 2025)

    GROUP BY
        s.`year`
)

SELECT
    fiscal_year,

    ROUND(
        net_revenue,
        2
    ) AS net_revenue,

    ROUND(
        gross_profit,
        2
    ) AS gross_profit,

    ROUND(
        gross_profit /
        NULLIF(net_revenue, 0),
        4
    ) AS gross_margin_pct

FROM annual_metrics

ORDER BY
    fiscal_year;


-- ============================================================
-- QUERY 2: LINEAR TREND PARAMETERS
-- ============================================================

WITH annual_metrics AS (
    SELECT
        s.`year` AS fiscal_year,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE
        s.unit_price IS NOT NULL
        AND s.`year` IN (2023, 2024, 2025)

    GROUP BY
        s.`year`
),

gross_margin_history AS (
    SELECT
        fiscal_year,
        gross_profit /
            NULLIF(net_revenue, 0)
            AS gross_margin_pct
    FROM annual_metrics
),

regression_stats AS (
    SELECT
        COUNT(*) AS n,

        SUM(fiscal_year) AS sum_x,

        SUM(gross_margin_pct) AS sum_y,

        SUM(
            fiscal_year * gross_margin_pct
        ) AS sum_xy,

        SUM(
            fiscal_year * fiscal_year
        ) AS sum_x2

    FROM gross_margin_history
)

SELECT

    ROUND(
        (
            n * sum_xy
            - sum_x * sum_y
        )
        /
        NULLIF(
            n * sum_x2
            - sum_x * sum_x,
            0
        ),
        8
    ) AS trend_slope,

    ROUND(
        (
            sum_y
            -
            (
                (
                    n * sum_xy
                    - sum_x * sum_y
                )
                /
                NULLIF(
                    n * sum_x2
                    - sum_x * sum_x,
                    0
                )
            )
            * sum_x
        )
        / n,
        8
    ) AS trend_intercept

FROM regression_stats;


-- ============================================================
-- QUERY 3: 2026 GROSS MARGIN FORECAST
-- ============================================================

WITH annual_metrics AS (
    SELECT
        s.`year` AS fiscal_year,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE
        s.unit_price IS NOT NULL
        AND s.`year` IN (2023, 2024, 2025)

    GROUP BY
        s.`year`
),

gross_margin_history AS (
    SELECT
        fiscal_year,

        gross_profit /
            NULLIF(net_revenue, 0)
            AS gross_margin_pct

    FROM annual_metrics
),

regression_stats AS (
    SELECT
        COUNT(*) AS n,

        SUM(fiscal_year) AS sum_x,

        SUM(gross_margin_pct) AS sum_y,

        SUM(
            fiscal_year * gross_margin_pct
        ) AS sum_xy,

        SUM(
            fiscal_year * fiscal_year
        ) AS sum_x2

    FROM gross_margin_history
),

trend AS (
    SELECT

        (
            n * sum_xy
            - sum_x * sum_y
        )
        /
        NULLIF(
            n * sum_x2
            - sum_x * sum_x,
            0
        ) AS slope,

        (
            sum_y
            -
            (
                (
                    n * sum_xy
                    - sum_x * sum_y
                )
                /
                NULLIF(
                    n * sum_x2
                    - sum_x * sum_x,
                    0
                )
            )
            * sum_x
        )
        / n AS intercept

    FROM regression_stats
)

SELECT

    2026 AS forecast_year,

    ROUND(
        slope,
        8
    ) AS trend_slope,

    ROUND(
        intercept,
        8
    ) AS trend_intercept,

    ROUND(
        (
            slope * 2026
            + intercept
        ),
        4
    ) AS forecast_gross_margin_pct,

    ROUND(slope * 100, 3) AS slope_percentage_points_per_year,
    CASE
        WHEN ABS(slope) < 0.002
            THEN 'Broadly stable'
        WHEN slope > 0
            THEN 'Slightly improving'
        ELSE 'Slightly declining'
    END AS margin_trend,
    'Trend continuation only (3 annual points)' AS forecast_note

FROM trend;

-- ============================================================
-- QUERY 4: BACK-TEST
-- Fit the same trend on 2023-2024 only, predict 2025, compare to actual.
-- ============================================================

WITH annual AS (
    SELECT
        s.`year` - 2022 AS x,
        SUM(
            s.quantity * s.unit_price * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) / SUM(s.quantity * s.unit_price * (1 - s.discount_pct)) AS y
    FROM sales_cleaned s
    JOIN dim_product p
        ON p.product_id = s.product_id
    WHERE s.unit_price IS NOT NULL
      AND s.`year` IN (2023, 2024)
    GROUP BY s.`year`
),
stats AS (
    SELECT COUNT(*) AS n, SUM(x) AS sx, SUM(y) AS sy, SUM(x * y) AS sxy, SUM(x * x) AS sxx
    FROM annual
),
fit AS (
    SELECT n, sx, sy, (n * sxy - sx * sy) / (n * sxx - sx * sx) AS slope
    FROM stats
)
SELECT
    ROUND((sy - slope * sx) / n + slope * 3, 4) AS predicted_2025,
    (
        SELECT ROUND(
            SUM(s.quantity * s.unit_price * (1 - s.discount_pct) - s.quantity * p.unit_cost)
            / SUM(s.quantity * s.unit_price * (1 - s.discount_pct)),
            4
        )
        FROM sales_cleaned s
        JOIN dim_product p
            ON p.product_id = s.product_id
        WHERE s.unit_price IS NOT NULL
          AND s.`year` = 2025
    ) AS actual_2025
FROM fit;

-- ============================================================
-- QUERY 5: 2026 GROSS PROFIT UNDER REVENUE SCENARIOS
-- Margin held at the 2025 level, and at the Query 3 trend forecast.
-- ============================================================

WITH annual AS (
    SELECT
        s.`year` - 2022 AS x,
        SUM(s.quantity * s.unit_price * (1 - s.discount_pct)) AS revenue,
        SUM(
            s.quantity * s.unit_price * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit
    FROM sales_cleaned s
    JOIN dim_product p
        ON p.product_id = s.product_id
    WHERE s.unit_price IS NOT NULL
    GROUP BY s.`year`
),
stats AS (
    SELECT COUNT(*) AS n, SUM(x) AS sx, SUM(gross_profit / revenue) AS sy,
           SUM(x * gross_profit / revenue) AS sxy, SUM(x * x) AS sxx
    FROM annual
),
fit AS (
    SELECT n, sx, sy, (n * sxy - sx * sy) / (n * sxx - sx * sx) AS slope FROM stats
),
trend AS (
    SELECT (sy - slope * sx) / n + slope * 4 AS gm_2026 FROM fit
),
base AS (
    SELECT revenue AS revenue_2025, gross_profit / revenue AS gm_2025
    FROM annual
    WHERE x = 3
),
scen AS (
    SELECT -0.05 AS revenue_change
    UNION ALL SELECT 0.00
    UNION ALL SELECT 0.05
)
SELECT
    sc.revenue_change,
    ROUND(b.revenue_2025 * (1 + sc.revenue_change), 0) AS revenue_2026,
    ROUND(t.gm_2026, 4) AS trend_gross_margin_2026,
    ROUND(b.revenue_2025 * (1 + sc.revenue_change) * t.gm_2026, 0) AS gross_profit_at_trend_margin,
    ROUND(b.revenue_2025 * (1 + sc.revenue_change) * b.gm_2025, 0) AS gross_profit_at_2025_margin
FROM scen sc
CROSS JOIN trend t
CROSS JOIN base b
ORDER BY sc.revenue_change;