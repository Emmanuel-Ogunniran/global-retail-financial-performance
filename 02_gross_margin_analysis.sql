USE global_retail;

-- ============================================================
-- 02_GROSS_MARGIN_ANALYSIS
-- ============================================================

-- ============================================================
-- QUERY 1: ANNUAL GROSS MARGIN
-- ============================================================

WITH sales_metrics AS (
    SELECT
        YEAR(s.`date`) AS fiscal_year,

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

    GROUP BY YEAR(s.`date`)
)

SELECT
    fiscal_year,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(gross_profit, 2) AS gross_profit,

    ROUND(
        gross_profit / NULLIF(net_revenue, 0),
        4
    ) AS gross_margin_pct

FROM sales_metrics

ORDER BY fiscal_year;

-- ============================================================
-- QUERY 2: GROSS MARGIN BY CATEGORY
-- ============================================================

WITH sales_metrics AS (
    SELECT
        YEAR(s.`date`) AS fiscal_year,
        p.category,

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
        p.category
)

SELECT
    fiscal_year,
    category,

    ROUND(net_revenue, 2) AS net_revenue,

    ROUND(gross_profit, 2) AS gross_profit,

    ROUND(
        gross_profit / NULLIF(net_revenue, 0),
        4
    ) AS gross_margin_pct

FROM sales_metrics

ORDER BY
    fiscal_year,
    gross_margin_pct;
    
-- ============================================================
-- QUERY 3: CATEGORY YEAR-OVER-YEAR REVENUE CHANGE
-- ============================================================

WITH category_revenue AS (
    SELECT
        YEAR(s.`date`) AS fiscal_year,
        p.category,

        SUM(
            s.quantity * s.unit_price *
            (1 - s.discount_pct)
        ) AS net_revenue

    FROM sales_cleaned s

    JOIN dim_product p
        ON s.product_id = p.product_id

    WHERE s.unit_price IS NOT NULL

    GROUP BY
        YEAR(s.`date`),
        p.category
),

category_change AS (
    SELECT
        category,
        fiscal_year,
        net_revenue,

        LAG(net_revenue) OVER (
            PARTITION BY category
            ORDER BY fiscal_year
        ) AS previous_year_revenue

    FROM category_revenue
)

SELECT
    fiscal_year,
    category,

    ROUND(net_revenue, 2) AS net_revenue,

    ROUND(previous_year_revenue, 2) AS previous_year_revenue,

    ROUND(
        net_revenue - previous_year_revenue,
        2
    ) AS revenue_change,

    ROUND(
        (
            net_revenue - previous_year_revenue
        )
        / NULLIF(previous_year_revenue, 0),
        4
    ) AS revenue_growth_pct

FROM category_change

ORDER BY
    fiscal_year,
    revenue_growth_pct;

-- ============================================================
-- QUERY 4: CATEGORY GROSS MARGIN CHANGE
-- ============================================================

WITH category_metrics AS (
    SELECT
        YEAR(s.`date`) AS fiscal_year,
        p.category,

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
        p.category
),

margin_metrics AS (
    SELECT
        fiscal_year,
        category,
        net_revenue,
        gross_profit,

        gross_profit /
        NULLIF(net_revenue, 0) AS gross_margin_pct

    FROM category_metrics
),

margin_change AS (
    SELECT
        *,
        LAG(gross_margin_pct) OVER (
            PARTITION BY category
            ORDER BY fiscal_year
        ) AS previous_year_margin

    FROM margin_metrics
)

SELECT
    fiscal_year,
    category,

    ROUND(gross_margin_pct, 4)
        AS gross_margin_pct,

    ROUND(previous_year_margin, 4)
        AS previous_year_margin,

    ROUND(
        gross_margin_pct - previous_year_margin,
        4
    ) AS margin_change

FROM margin_change

ORDER BY
    fiscal_year,
    category;