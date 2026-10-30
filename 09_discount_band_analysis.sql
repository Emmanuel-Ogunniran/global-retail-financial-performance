USE global_retail;

-- ============================================================
-- 09_DISCOUNT_BAND_ANALYSIS
-- What do deeper discounts cost in margin, and does volume per line
-- respond? Observational only: quantity is per sales LINE, not
-- store traffic or basket count. Rows with missing price excluded.
-- ============================================================

-- ============================================================
-- QUERY 1: MARGIN AND QUANTITY BY DISCOUNT BAND (all years)
-- ============================================================

SELECT
    CASE
        WHEN s.discount_pct = 0    THEN '1) 0%'
        WHEN s.discount_pct <= 0.10 THEN '2) 0-10%'
        WHEN s.discount_pct <= 0.20 THEN '3) 10-20%'
        ELSE                             '4) 20%+'
    END AS discount_band,
    COUNT(*) AS sales_lines,
    ROUND(AVG(s.quantity), 2) AS avg_quantity_per_line,
    ROUND(SUM(s.quantity * s.unit_price), 0) AS gross_revenue,
    ROUND(SUM(s.quantity * s.unit_price * s.discount_pct), 0) AS discount_value,
    ROUND(
        SUM(s.quantity * s.unit_price * (1 - s.discount_pct) - s.quantity * p.unit_cost)
        / SUM(s.quantity * s.unit_price * (1 - s.discount_pct)),
        4
    ) AS gross_margin_after_discount,
    ROUND(
        (SUM(s.quantity * s.unit_price) - SUM(s.quantity * p.unit_cost))
        / SUM(s.quantity * s.unit_price),
        4
    ) AS gross_margin_before_discount
FROM sales_cleaned s
JOIN dim_product p
    ON p.product_id = s.product_id
WHERE s.unit_price IS NOT NULL
GROUP BY
    CASE
        WHEN s.discount_pct = 0    THEN '1) 0%'
        WHEN s.discount_pct <= 0.10 THEN '2) 0-10%'
        WHEN s.discount_pct <= 0.20 THEN '3) 10-20%'
        ELSE                             '4) 20%+'
    END
ORDER BY discount_band;

-- ============================================================
-- QUERY 2: DISCOUNT LEAKAGE BY YEAR
-- ============================================================

SELECT
    s.`year` AS fiscal_year,
    ROUND(SUM(s.quantity * s.unit_price * s.discount_pct), 0) AS discount_value,
    ROUND(
        SUM(s.quantity * s.unit_price * s.discount_pct)
        / SUM(s.quantity * s.unit_price),
        4
    ) AS discount_pct_of_gross_revenue
FROM sales_cleaned s
WHERE s.unit_price IS NOT NULL
GROUP BY s.`year`
ORDER BY s.`year`;

-- ============================================================
-- QUERY 3: 2025 DISCOUNT DOLLARS BY BAND, AND VS THE 5% COST CUT
-- ============================================================

SELECT
    CASE
        WHEN s.discount_pct > 0.20 THEN '20%+'
        WHEN s.discount_pct > 0.10 THEN '10-20%'
        WHEN s.discount_pct > 0    THEN '0-10%'
        ELSE 'none'
    END AS discount_band,
    ROUND(SUM(s.quantity * s.unit_price * s.discount_pct), 0) AS discount_value,
    ROUND(
        SUM(s.quantity * s.unit_price * s.discount_pct)
        / SUM(SUM(s.quantity * s.unit_price * s.discount_pct)) OVER (),
        4
    ) AS share_of_2025_discount,
    ROUND(
        (SELECT SUM(rent + utilities + labor + other_costs) * 0.05
         FROM store_expenses
         WHERE `date` >= '2025-01-01' AND `date` < '2026-01-01'),
        0
    ) AS five_pct_cost_cut_for_comparison
FROM sales_cleaned s
WHERE s.unit_price IS NOT NULL
  AND s.`year` = 2025
GROUP BY
    CASE
        WHEN s.discount_pct > 0.20 THEN '20%+'
        WHEN s.discount_pct > 0.10 THEN '10-20%'
        WHEN s.discount_pct > 0    THEN '0-10%'
        ELSE 'none'
    END
ORDER BY discount_value DESC;