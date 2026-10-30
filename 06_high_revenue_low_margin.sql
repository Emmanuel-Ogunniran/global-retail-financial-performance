USE global_retail;

-- ============================================================
-- 06_HIGH REVENUE LOW MARGIN
-- ============================================================

-- ============================================================
-- QUERY 1: 2025 PRODUCT REVENUE AND GROSS MARGIN
-- ============================================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
        ) AS revenue,

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
        AND s.`year` = 2025

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)

SELECT
    product_id,
    product_name,
    category,

    ROUND(revenue, 2) AS revenue,

    ROUND(gross_profit, 2) AS gross_profit,

    ROUND(
        gross_profit /
        NULLIF(revenue, 0),
        4
    ) AS gross_margin_pct

FROM product_metrics

ORDER BY
    revenue DESC;
    
-- ============================================================
-- QUERY 2: PRODUCT REVENUE AND MARGIN RANKING
-- ============================================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
        ) AS revenue,

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
        AND s.`year` = 2025

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked AS (
    SELECT
        product_id,
        product_name,
        category,
        revenue,
        gross_profit,

        gross_profit /
            NULLIF(revenue, 0)
            AS gross_margin_pct,

        NTILE(4) OVER (
            ORDER BY revenue DESC
        ) AS revenue_quartile,

        NTILE(4) OVER (
            ORDER BY
                gross_profit /
                NULLIF(revenue, 0)
        ) AS margin_quartile

    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    category,

    ROUND(revenue, 2) AS revenue,

    ROUND(gross_profit, 2) AS gross_profit,

    ROUND(
        gross_margin_pct,
        4
    ) AS gross_margin_pct,

    revenue_quartile,
    margin_quartile

FROM ranked

ORDER BY
    revenue DESC;
    
-- ============================================================
-- QUERY 3: HIGH-REVENUE / LOW-MARGIN PRODUCTS
-- ============================================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
        ) AS revenue,

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
        AND s.`year` = 2025

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked AS (
    SELECT
        *,
        
        gross_profit /
            NULLIF(revenue, 0)
            AS gross_margin_pct,

        NTILE(4) OVER (
            ORDER BY revenue DESC
        ) AS revenue_quartile,

        NTILE(4) OVER (
            ORDER BY
                gross_profit /
                NULLIF(revenue, 0)
        ) AS margin_quartile

    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    category,

    ROUND(revenue, 2) AS revenue,

    ROUND(gross_profit, 2) AS gross_profit,

    ROUND(
        gross_margin_pct,
        4
    ) AS gross_margin_pct,

    revenue_quartile,
    margin_quartile,

    'High Revenue / Low Margin'
        AS strategic_flag

FROM ranked

WHERE
    revenue_quartile = 1
    AND margin_quartile = 1

ORDER BY
    revenue DESC;
    
-- ============================================================
-- QUERY 4: HIGH-REVENUE / LOW-MARGIN ECONOMIC OPPORTUNITY
-- ============================================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(
            s.quantity * s.unit_price
            * (1 - s.discount_pct)
        ) AS revenue,

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
        AND s.`year` = 2025

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked AS (
    SELECT
        *,
        
        gross_profit /
            NULLIF(revenue, 0)
            AS gross_margin_pct,

        NTILE(4) OVER (
            ORDER BY revenue DESC
        ) AS revenue_quartile,

        NTILE(4) OVER (
            ORDER BY
                gross_profit /
                NULLIF(revenue, 0)
        ) AS margin_quartile

    FROM product_metrics
),

totals AS (
    SELECT
        SUM(revenue) AS total_revenue,
        SUM(gross_profit) AS total_gross_profit
    FROM ranked
)

SELECT
    r.product_id,
    r.product_name,
    r.category,

    ROUND(
        r.revenue,
        2
    ) AS revenue,

    ROUND(
        r.gross_profit,
        2
    ) AS gross_profit,

    ROUND(
        r.gross_margin_pct,
        4
    ) AS gross_margin_pct,

    ROUND(
        r.revenue /
        NULLIF(t.total_revenue, 0),
        4
    ) AS revenue_share,

    ROUND(
        r.gross_profit /
        NULLIF(t.total_gross_profit, 0),
        4
    ) AS gross_profit_share,

    ROUND(
        GREATEST(
            r.revenue * (
                t.total_gross_profit / NULLIF(t.total_revenue, 0)
            )
            - r.gross_profit,
            0
        ),
        2
    ) AS gross_profit_opportunity,

    ROUND(
        t.total_revenue,
        2
    ) AS total_2025_revenue,

    ROUND(
        t.total_gross_profit,
        2
    ) AS total_2025_gross_profit

FROM ranked r

CROSS JOIN totals t

WHERE
    r.revenue_quartile = 1
    AND r.margin_quartile = 1

ORDER BY
    r.revenue DESC;

-- ============================================================
-- QUERY 5: TOTAL MARGIN-AT-RISK ACROSS ALL PRODUCTS (2025)
-- Benchmark = company-wide 2025 gross margin (calculated, not typed).
-- Shows how big the whole product-pricing prize is.
-- ============================================================

WITH product_metrics AS (
    SELECT
        p.product_id,
        SUM(s.quantity * s.unit_price * (1 - s.discount_pct)) AS revenue,
        SUM(
            s.quantity * s.unit_price * (1 - s.discount_pct)
            - s.quantity * p.unit_cost
        ) AS gross_profit
    FROM sales_cleaned s
    JOIN dim_product p
        ON s.product_id = p.product_id
    WHERE s.unit_price IS NOT NULL
      AND s.`year` = 2025
    GROUP BY p.product_id
),
totals AS (
    SELECT
        SUM(revenue) AS total_revenue,
        SUM(gross_profit) / SUM(revenue) AS benchmark_margin
    FROM product_metrics
)
SELECT
    ROUND(t.benchmark_margin, 4) AS benchmark_margin,
    COUNT(*) AS products_below_benchmark,
    ROUND(SUM(m.revenue * t.benchmark_margin - m.gross_profit), 0) AS total_margin_at_risk,
    ROUND(SUM(m.revenue * t.benchmark_margin - m.gross_profit) / MAX(t.total_revenue), 4) AS pct_of_revenue
FROM product_metrics m
CROSS JOIN totals t
WHERE m.gross_profit / NULLIF(m.revenue, 0) < t.benchmark_margin
GROUP BY t.benchmark_margin;