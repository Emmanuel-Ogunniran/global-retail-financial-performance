USE global_retail;

-- ============================================================
-- 07_COST REDUCTION SCENERIO
-- ============================================================

-- ============================================================
-- QUERY 1: 2025 COST STRUCTURE
-- ============================================================

WITH cost_summary AS (
    SELECT
        SUM(rent) AS rent,
        SUM(utilities) AS utilities,
        SUM(labor) AS labor,
        SUM(other_costs) AS other_costs,
        SUM(
            rent + utilities + labor + other_costs
        ) AS total_operating_cost
    FROM store_expenses
    WHERE `date` >= '2025-01-01'
      AND `date` < '2026-01-01'
)
SELECT
    ROUND(rent, 2) AS rent,
    ROUND(utilities, 2) AS utilities,
    ROUND(labor, 2) AS labor,
    ROUND(other_costs, 2) AS other_costs,
    ROUND(total_operating_cost, 2) AS total_operating_cost,

    ROUND(
        rent / NULLIF(total_operating_cost, 0),
        4
    ) AS rent_share,

    ROUND(
        utilities / NULLIF(total_operating_cost, 0),
        4
    ) AS utilities_share,

    ROUND(
        labor / NULLIF(total_operating_cost, 0),
        4
    ) AS labor_share,

    ROUND(
        other_costs / NULLIF(total_operating_cost, 0),
        4
    ) AS other_costs_share

FROM cost_summary;

-- ============================================================
-- QUERY 2: 5% NON-LABOR COST REDUCTION SCENARIO
-- ============================================================

WITH cost_summary AS (
    SELECT
        SUM(rent) AS rent,
        SUM(utilities) AS utilities,
        SUM(labor) AS labor,
        SUM(other_costs) AS other_costs

    FROM store_expenses

    WHERE
        `date` >= '2025-01-01'
        AND `date` < '2026-01-01'
),

baseline AS (
    SELECT
        rent,
        utilities,
        labor,
        other_costs,

        rent
        + utilities
        + labor
        + other_costs
            AS total_operating_cost,

        rent
        + utilities
        + other_costs
            AS non_labor_cost

    FROM cost_summary
)

SELECT
    ROUND(
        total_operating_cost,
        2
    ) AS baseline_operating_cost,

    ROUND(
        non_labor_cost,
        2
    ) AS baseline_non_labor_cost,

    ROUND(
        non_labor_cost * 0.05,
        2
    ) AS non_labor_saving_5pct,

    ROUND(
        total_operating_cost
        - (non_labor_cost * 0.05),
        2
    ) AS operating_cost_after_5pct_non_labor_cut,

    ROUND(
        (non_labor_cost * 0.05)
        / NULLIF(total_operating_cost, 0),
        4
    ) AS total_cost_reduction_pct

FROM baseline;

-- ============================================================
-- QUERY 3: WHAT NON-LABOR REDUCTION IS REQUIRED TO ACHIEVE A 5% TOTAL COST CUT?
-- ============================================================

WITH cost_summary AS (
    SELECT
        SUM(rent) AS rent,
        SUM(utilities) AS utilities,
        SUM(labor) AS labor,
        SUM(other_costs) AS other_costs
    FROM store_expenses
    WHERE `date` >= '2025-01-01'
      AND `date` < '2026-01-01'
),
baseline AS (
    SELECT
        rent + utilities + labor + other_costs
            AS total_operating_cost,

        rent + utilities + other_costs
            AS non_labor_cost
    FROM cost_summary
)
SELECT
    ROUND(total_operating_cost, 2)
        AS baseline_operating_cost,

    ROUND(
        total_operating_cost * 0.05,
        2
    ) AS required_5pct_saving,

    ROUND(non_labor_cost, 2)
        AS non_labor_cost,

    ROUND(
        (total_operating_cost * 0.05)
        / NULLIF(non_labor_cost, 0),
        4
    ) AS required_non_labor_reduction_pct

FROM baseline;

-- ============================================================
-- QUERY 4: WHERE SHOULD THE COST REDUCTION COME OUT FROM?
-- ============================================================

WITH cost_summary AS (
    SELECT
        SUM(rent) AS rent,
        SUM(utilities) AS utilities,
        SUM(other_costs) AS other_costs
    FROM store_expenses
    WHERE `date` >= '2025-01-01'
      AND `date` < '2026-01-01'
),
cost_categories AS (
    SELECT 'Rent' AS cost_category, rent AS cost
    FROM cost_summary

    UNION ALL

    SELECT 'Utilities', utilities
    FROM cost_summary

    UNION ALL

    SELECT 'Other Costs', other_costs
    FROM cost_summary
),
total AS (
    SELECT SUM(cost) AS total_non_labor_cost
    FROM cost_categories
)
SELECT
    c.cost_category,
    ROUND(c.cost, 2) AS cost,
    ROUND(
        c.cost / NULLIF(t.total_non_labor_cost, 0),
        4
    ) AS share_of_non_labor_cost,

    ROUND(
        c.cost * 0.05,
        2
    ) AS saving_if_cut_5pct

FROM cost_categories c
CROSS JOIN total t
ORDER BY c.cost DESC;

-- ============================================================
-- QUERY 5: STORE-LEVEL NON-LABOR SAVING OPPORTUNITY
-- ============================================================

WITH store_costs AS (
    SELECT
        store_id,

        SUM(rent) AS rent,
        SUM(utilities) AS utilities,
        SUM(labor) AS labor,
        SUM(other_costs) AS other_costs,

        SUM(
            rent
            + utilities
            + labor
            + other_costs
        ) AS total_operating_cost

    FROM store_expenses

    WHERE
        `date` >= '2025-01-01'
        AND `date` < '2026-01-01'

    GROUP BY
        store_id
)

SELECT
    store_id,

    ROUND(
        total_operating_cost,
        2
    ) AS total_operating_cost,

    ROUND(
        rent
        + utilities
        + other_costs,
        2
    ) AS non_labor_cost,

    ROUND(
        (
            rent
            + utilities
            + other_costs
        ) * 0.05,
        2
    ) AS non_labor_saving_5pct,

    ROUND(
        labor,
        2
    ) AS labor_protected,

    ROUND(
        (
            rent
            + utilities
            + other_costs
        )
        / NULLIF(
            total_operating_cost,
            0
        ),
        4
    ) AS non_labor_cost_share

FROM store_costs

ORDER BY
    4 DESC;

-- ============================================================
-- QUERY 6: COST-CUT SIMULATOR (2025 base, labor protected)
-- A cut is a % of TOTAL operating cost, funded only from non-labor cost.
-- ============================================================

WITH cost AS (
    SELECT
        SUM(rent + utilities + labor + other_costs) AS operating_cost,
        SUM(rent + utilities + other_costs) AS non_labor_cost
    FROM store_expenses
    WHERE `date` >= '2025-01-01'
      AND `date` < '2026-01-01'
),
fin AS (
    SELECT
        SUM(s.quantity * s.unit_price * (1 - s.discount_pct)) AS net_revenue,
        SUM(
            s.quantity * s.unit_price * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit
    FROM sales_cleaned s
    JOIN dim_product p
        ON p.product_id = s.product_id
    WHERE s.unit_price IS NOT NULL
      AND s.`year` = 2025
),
scenarios AS (
    SELECT 0.00 AS cut_pct
    UNION ALL SELECT 0.01
    UNION ALL SELECT 0.02
    UNION ALL SELECT 0.03
    UNION ALL SELECT 0.04
    UNION ALL SELECT 0.05
    UNION ALL SELECT 0.07
    UNION ALL SELECT 0.10
)
SELECT
    sc.cut_pct,
    ROUND(c.operating_cost * sc.cut_pct, 0) AS savings,
    ROUND(c.operating_cost * (1 - sc.cut_pct), 0) AS simulated_operating_cost,
    ROUND(f.gross_profit - c.operating_cost * (1 - sc.cut_pct), 0) AS simulated_net_operating_profit,
    ROUND(
        (f.gross_profit - c.operating_cost * (1 - sc.cut_pct)) / f.net_revenue,
        4
    ) AS simulated_net_margin,
    ROUND(c.operating_cost * sc.cut_pct / c.non_labor_cost, 4) AS implied_non_labor_cut,
    ROUND(
        c.operating_cost * (1 - sc.cut_pct) / (f.gross_profit / f.net_revenue)
        - f.net_revenue,
        0
    ) AS revenue_gap_to_break_even
FROM scenarios sc
CROSS JOIN cost c
CROSS JOIN fin f
ORDER BY sc.cut_pct;

-- ============================================================
-- QUERY 7: WHERE THE 5% SHOULD COME FROM
-- Spread across value-destroying stores only (stores with positive
-- 2025 operating profit are protected), pro-rata to non-labor cost.
-- ============================================================

WITH store_sales AS (
    SELECT
        s.store_id,
        SUM(
            s.quantity * s.unit_price * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit
    FROM sales_cleaned s
    JOIN dim_product p
        ON p.product_id = s.product_id
    WHERE s.unit_price IS NOT NULL
      AND s.`year` = 2025
    GROUP BY s.store_id
),
store_cost AS (
    SELECT
        store_id,
        SUM(rent + utilities + labor + other_costs) AS operating_cost,
        SUM(rent + utilities + other_costs) AS non_labor_cost
    FROM store_expenses
    WHERE `date` >= '2025-01-01'
      AND `date` < '2026-01-01'
    GROUP BY store_id
),
store_base AS (
    SELECT
        c.store_id,
        c.operating_cost,
        c.non_labor_cost,
        s.gross_profit - c.operating_cost AS net_operating_profit
    FROM store_cost c
    JOIN store_sales s
        ON s.store_id = c.store_id
),
target AS (
    SELECT SUM(operating_cost) * 0.05 AS target_saving
    FROM store_base
),
pool AS (
    SELECT SUM(non_labor_cost) AS pool_cost
    FROM store_base
    WHERE net_operating_profit < 0
)
SELECT
    b.store_id,
    ROUND(b.net_operating_profit, 0) AS profit_before,
    ROUND(b.non_labor_cost, 0) AS non_labor_cost,
    ROUND(
        CASE WHEN b.net_operating_profit < 0
             THEN t.target_saving * b.non_labor_cost / pl.pool_cost
             ELSE 0 END,
        0
    ) AS proposed_saving,
    ROUND(
        CASE WHEN b.net_operating_profit < 0
             THEN t.target_saving / pl.pool_cost
             ELSE 0 END,
        4
    ) AS cut_pct_of_store_non_labor,
    ROUND(
        b.net_operating_profit
        + CASE WHEN b.net_operating_profit < 0
               THEN t.target_saving * b.non_labor_cost / pl.pool_cost
               ELSE 0 END,
        0
    ) AS profit_after
FROM store_base b
CROSS JOIN target t
CROSS JOIN pool pl
ORDER BY proposed_saving DESC;