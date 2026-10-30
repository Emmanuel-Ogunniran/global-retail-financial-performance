USE global_retail;

-- ============================================================
-- 03_STORE_PROFITABILITY
-- ============================================================

-- ============================================================
-- QUERY 1: STORE PROFITABILITY BY YEAR
-- ============================================================

WITH sales_metrics AS (
    SELECT
        YEAR(s.`date`) AS fiscal_year,
        s.store_id,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE s.unit_price IS NOT NULL

    GROUP BY
        YEAR(s.`date`),
        s.store_id
),

expense_metrics AS (
    SELECT
        YEAR(`date`) AS fiscal_year,
        store_id,

        SUM(
            rent +
            utilities +
            labor +
            other_costs
        ) AS operating_cost

    FROM store_expenses

    GROUP BY
        YEAR(`date`),
        store_id
)

SELECT
    s.fiscal_year,
    s.store_id,

    ROUND(s.net_revenue, 2) AS net_revenue,

    ROUND(s.gross_profit, 2) AS gross_profit,

    ROUND(e.operating_cost, 2) AS operating_cost,

    ROUND(
        e.operating_cost /
        NULLIF(s.net_revenue, 0),
        4
    ) AS operating_cost_pct,

    ROUND(
        s.gross_profit - e.operating_cost,
        2
    ) AS net_operating_profit,

    ROUND(
        (
            s.gross_profit - e.operating_cost
        )
        / NULLIF(s.net_revenue, 0),
        4
    ) AS net_operating_margin

FROM sales_metrics s

JOIN expense_metrics e
    ON s.fiscal_year = e.fiscal_year
    AND s.store_id = e.store_id

ORDER BY
    s.fiscal_year,
    net_operating_profit;
    
-- ============================================================
-- QUERY 2: STORE PROFITABILITY - 2025 DECISION YEAR
-- ============================================================

WITH sales_metrics AS (
    SELECT
        s.store_id,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE
        s.unit_price IS NOT NULL
        AND s.`year` = 2025

    GROUP BY s.store_id
),

expense_metrics AS (
    SELECT
        store_id,

        SUM(
            rent +
            utilities +
            labor +
            other_costs
        ) AS operating_cost

    FROM store_expenses

    WHERE YEAR(`date`) = 2025

    GROUP BY store_id
)

SELECT
    s.store_id,

    ROUND(s.net_revenue, 2) AS net_revenue,

    ROUND(s.gross_profit, 2) AS gross_profit,

    ROUND(e.operating_cost, 2) AS operating_cost,

    ROUND(
        e.operating_cost /
        NULLIF(s.net_revenue, 0),
        4
    ) AS operating_cost_pct,

    ROUND(
        s.gross_profit - e.operating_cost,
        2
    ) AS net_operating_profit,

    ROUND(
        (
            s.gross_profit - e.operating_cost
        ) / NULLIF(s.net_revenue, 0),
        4
    ) AS net_operating_margin

FROM sales_metrics s

JOIN expense_metrics e
    ON s.store_id = e.store_id

ORDER BY
    net_operating_profit;

-- ============================================================
-- QUERY 3: STORE OPERATING COST BURDEN
-- ============================================================

WITH store_metrics AS (
    SELECT
        s.store_id,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
        ) AS net_revenue

    FROM sales_cleaned s

    WHERE
        s.unit_price IS NOT NULL
        AND s.`year` = 2025

    GROUP BY s.store_id
),

expense_metrics AS (
    SELECT
        store_id,

        SUM(
            rent +
            utilities +
            labor +
            other_costs
        ) AS operating_cost

    FROM store_expenses

    WHERE YEAR(`date`) = 2025

    GROUP BY store_id
)

SELECT
    s.store_id,

    ROUND(s.net_revenue, 2) AS net_revenue,

    ROUND(e.operating_cost, 2) AS operating_cost,

    ROUND(
        e.operating_cost /
        NULLIF(s.net_revenue, 0),
        4
    ) AS operating_cost_pct

FROM store_metrics s

JOIN expense_metrics e
    ON s.store_id = e.store_id

ORDER BY
    operating_cost_pct DESC;
    
-- ============================================================
-- QUERY 4: 2025 STORE ECONOMIC ZONES
-- ============================================================

WITH store_metrics AS (
    SELECT
        s.store_id,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE
        s.unit_price IS NOT NULL
        AND s.`year` = 2025

    GROUP BY s.store_id
),

expense_metrics AS (
    SELECT
        store_id,

        SUM(
            rent +
            utilities +
            labor +
            other_costs
        ) AS operating_cost

    FROM store_expenses

    WHERE YEAR(`date`) = 2025

    GROUP BY store_id
),

profitability AS (
    SELECT
        s.store_id,
        s.net_revenue,
        s.gross_profit,
        e.operating_cost,

        e.operating_cost /
            NULLIF(s.net_revenue, 0)
            AS operating_cost_pct,

        s.gross_profit - e.operating_cost
            AS net_operating_profit,

        (
            s.gross_profit - e.operating_cost
        ) / NULLIF(s.net_revenue, 0)
            AS net_operating_margin

    FROM store_metrics s

    JOIN expense_metrics e
        ON s.store_id = e.store_id
)

SELECT
    store_id,

    ROUND(net_revenue, 2)
        AS net_revenue,

    ROUND(gross_profit, 2)
        AS gross_profit,

    ROUND(operating_cost, 2)
        AS operating_cost,

    ROUND(operating_cost_pct, 4)
        AS operating_cost_pct,

    ROUND(net_operating_profit, 2)
        AS net_operating_profit,

    ROUND(net_operating_margin, 4)
        AS net_operating_margin,

    CASE
        WHEN net_operating_margin >= 0.05
            THEN 'A - Sustainable'

        WHEN net_operating_margin >= -0.05
            THEN 'B - Near break-even'

        WHEN operating_cost_pct <= 1.50
            THEN 'C - Revenue recovery needed'

        ELSE 'D - Structural under-utilization'
    END AS economic_zone

FROM profitability

ORDER BY
    economic_zone,
    net_operating_profit;

-- ============================================================
-- QUERY 5: STORE BREAK-EVEN REVENUE
-- ============================================================

WITH store_metrics AS (
    SELECT
        s.store_id,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE YEAR(`date`) = 2025

    GROUP BY s.store_id
),

expense_metrics AS (
    SELECT
        store_id,

        SUM(
            rent +
            utilities +
            labor +
            other_costs
        ) AS operating_cost

    FROM store_expenses

    WHERE YEAR(`date`) = 2025

    GROUP BY store_id
),

store_profitability AS (
    SELECT
        s.store_id,
        s.net_revenue,
        s.gross_profit,
        e.operating_cost,

        s.gross_profit /
            NULLIF(s.net_revenue, 0)
            AS gross_margin_pct

    FROM store_metrics s

    JOIN expense_metrics e
        ON s.store_id = e.store_id
)

SELECT
    store_id,

    ROUND(net_revenue, 2)
        AS actual_revenue,

    ROUND(gross_margin_pct, 4)
        AS gross_margin_pct,

    ROUND(operating_cost, 2)
        AS operating_cost,

    ROUND(
        operating_cost /
        NULLIF(gross_margin_pct, 0),
        2
    ) AS break_even_revenue,

    ROUND(
        (
            operating_cost /
            NULLIF(gross_margin_pct, 0)
        ) - net_revenue,
        2
    ) AS additional_revenue_needed

FROM store_profitability

ORDER BY
    additional_revenue_needed DESC;

-- ============================================================
-- QUERY 6: OPERATING COST COMPOSITION BY STORE
-- ============================================================

SELECT
    store_id,

    ROUND(SUM(rent), 2) AS rent,

    ROUND(SUM(utilities), 2) AS utilities,

    ROUND(SUM(labor), 2) AS labor,

    ROUND(SUM(other_costs), 2) AS other_costs,

    ROUND(
        SUM(rent + utilities + labor + other_costs),
        2
    ) AS total_operating_cost

FROM store_expenses

WHERE YEAR(`date`) = 2025

GROUP BY store_id

ORDER BY total_operating_cost DESC;

-- ============================================================
-- QUERY 7: 2024 TO 2025 STORE ECONOMIC CHANGE
-- ============================================================

WITH store_year AS (
    SELECT
        s.store_id,
        s.`year`,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
        ) AS net_revenue,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE
        s.unit_price IS NOT NULL
        AND s.`year` IN (2024, 2025)

    GROUP BY
        s.store_id,
        s.`year`
),

expense_year AS (
    SELECT
        store_id,
        YEAR(`date`) AS `year`,

        SUM(
            rent +
            utilities +
            labor +
            other_costs
        ) AS operating_cost

    FROM store_expenses

    WHERE YEAR(`date`) IN (2024, 2025)

    GROUP BY
        store_id,
        YEAR(`date`)
),

store_profitability AS (
    SELECT
        s.store_id,
        s.`year`,
        s.net_revenue,
        s.gross_profit,
        e.operating_cost,

        s.gross_profit - e.operating_cost
            AS net_operating_profit,

        (
            s.gross_profit - e.operating_cost
        ) / NULLIF(s.net_revenue, 0)
            AS net_operating_margin

    FROM store_year s

    JOIN expense_year e
        ON s.store_id = e.store_id
        AND s.`year` = e.`year`
)

SELECT
    store_id,

    ROUND(
        MAX(
            CASE WHEN `year` = 2024
            THEN net_revenue END
        ), 2
    ) AS revenue_2024,

    ROUND(
        MAX(
            CASE WHEN `year` = 2025
            THEN net_revenue END
        ), 2
    ) AS revenue_2025,

    ROUND(
        MAX(
            CASE WHEN `year` = 2025
            THEN net_revenue END
        )
        -
        MAX(
            CASE WHEN `year` = 2024
            THEN net_revenue END
        ), 2
    ) AS revenue_change,

    ROUND(
        MAX(
            CASE WHEN `year` = 2024
            THEN net_operating_profit END
        ), 2
    ) AS nop_2024,

    ROUND(
        MAX(
            CASE WHEN `year` = 2025
            THEN net_operating_profit END
        ), 2
    ) AS nop_2025,

    ROUND(
        MAX(
            CASE WHEN `year` = 2025
            THEN net_operating_profit END
        )
        -
        MAX(
            CASE WHEN `year` = 2024
            THEN net_operating_profit END
        ), 2
    ) AS nop_change

FROM store_profitability

GROUP BY store_id

ORDER BY nop_change;