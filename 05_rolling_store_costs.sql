USE global_retail;

-- ============================================================
-- 05_ROLLING COST STORE
-- ============================================================

-- ============================================================
-- QUERY 1: MONTHLY STORE OPERATING COST
-- ============================================================

SELECT
    store_id,
    `date` AS month,

    ROUND(
        rent + utilities + labor + other_costs,
        2
    ) AS operating_cost

FROM store_expenses

ORDER BY
    store_id,
    month;

-- ============================================================
-- QUERY 2: ROLLING 3-MONTH OPERATING COST
-- ============================================================

WITH monthly_cost AS (
    SELECT
        store_id,
        `date` AS month,

        rent
        + utilities
        + labor
        + other_costs AS operating_cost

    FROM store_expenses
)

SELECT
    store_id,
    month,

    ROUND(
        operating_cost,
        2
    ) AS operating_cost,

    ROUND(
        AVG(operating_cost) OVER (
            PARTITION BY store_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_cost

FROM monthly_cost

ORDER BY
    store_id,
    month;

-- ============================================================
-- QUERY 3: MONTHLY COST VS ROLLING COST
-- ============================================================

WITH monthly_cost AS (
    SELECT
        store_id,
        `date` AS month,

        rent
        + utilities
        + labor
        + other_costs AS operating_cost

    FROM store_expenses
),

rolling_cost AS (
    SELECT
        store_id,
        month,
        operating_cost,

        AVG(operating_cost) OVER (
            PARTITION BY store_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3_month_cost

    FROM monthly_cost
)

SELECT
    store_id,
    month,

    ROUND(
        operating_cost,
        2
    ) AS operating_cost,

    ROUND(
        rolling_3_month_cost,
        2
    ) AS rolling_3_month_cost,

    ROUND(
        operating_cost - rolling_3_month_cost,
        2
    ) AS variance_from_rolling_cost,

    ROUND(
        (
            operating_cost - rolling_3_month_cost
        )
        / NULLIF(rolling_3_month_cost, 0),
        4
    ) AS variance_pct

FROM rolling_cost

ORDER BY
    store_id,
    month;
    
-- ============================================================
-- QUERY 4: STORE COST PRESSURE SUMMARY
-- ============================================================

WITH monthly_cost AS (
    SELECT
        store_id,
        `date` AS month,
        rent + utilities + labor + other_costs AS operating_cost
    FROM store_expenses
),

rolling_cost AS (
    SELECT
        store_id,
        month,
        operating_cost,
        AVG(operating_cost) OVER (
            PARTITION BY store_id
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3_month_cost
    FROM monthly_cost
),

valid_months AS (
    SELECT
        store_id,
        month,
        operating_cost,
        rolling_3_month_cost,
        operating_cost - rolling_3_month_cost
            AS variance_from_rolling_cost
    FROM (
        SELECT
            *,
            COUNT(*) OVER (
                PARTITION BY store_id
                ORDER BY month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) AS month_count
        FROM rolling_cost
    ) x
    WHERE month_count = 3
),

store_summary AS (
    SELECT
        store_id,
        AVG(operating_cost) AS avg_monthly_operating_cost,
        AVG(rolling_3_month_cost) AS avg_rolling_3_month_cost,
        MAX(rolling_3_month_cost) AS peak_rolling_3_month_cost,
        AVG(variance_from_rolling_cost) AS avg_variance_from_rolling_cost
    FROM valid_months
    GROUP BY store_id
)

SELECT
    store_id,
    ROUND(
        avg_monthly_operating_cost,
        2
    ) AS avg_monthly_operating_cost,

    ROUND(
        avg_rolling_3_month_cost,
        2
    ) AS avg_rolling_3_month_cost,

    ROUND(
        peak_rolling_3_month_cost,
        2
    ) AS peak_rolling_3_month_cost,

    ROUND(
        avg_variance_from_rolling_cost,
        2
    ) AS avg_variance_from_rolling_cost

FROM store_summary

ORDER BY
    avg_rolling_3_month_cost DESC;