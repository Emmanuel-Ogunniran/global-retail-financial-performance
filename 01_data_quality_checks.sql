USE global_retail;

-- ============================================================
-- 01_DATA_QUALITY_CHECKS
-- ============================================================

-- 1. ROW COUNTS
-- ============================================================

SELECT 'sales_cleaned' AS table_name, COUNT(*) AS row_count
FROM sales_cleaned

UNION ALL

SELECT 'dim_product', COUNT(*)
FROM dim_product

UNION ALL

SELECT 'dim_store', COUNT(*)
FROM dim_store

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dim_date

UNION ALL

SELECT 'promotions', COUNT(*)
FROM promotions

UNION ALL

SELECT 'store_expenses', COUNT(*)
FROM store_expenses;

-- ============================================================
-- 2. EXPECTED IMPORT ROW COUNTS
-- ============================================================

SELECT
    'sales_cleaned' AS table_name,
    18000 AS expected_rows,
    COUNT(*) AS actual_rows,
    CASE
        WHEN COUNT(*) = 18000 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM sales_cleaned

UNION ALL

SELECT
    'dim_product',
    69,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 69 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM dim_product

UNION ALL

SELECT
    'dim_store',
    12,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 12 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM dim_store

UNION ALL

SELECT
    'dim_date',
    1096,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 1096 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM dim_date

UNION ALL

SELECT
    'promotions',
    130,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 130 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM promotions

UNION ALL

SELECT
    'store_expenses',
    288,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 288 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM store_expenses;


-- 3. MISSING SALES PRICES
-- ============================================================

SELECT
    COUNT(*) AS missing_unit_price
FROM sales_cleaned
WHERE unit_price IS NULL;


-- 4. NEGATIVE QUANTITIES
-- ============================================================

SELECT
    COUNT(*) AS negative_quantity_rows
FROM sales_cleaned
WHERE quantity < 0;


-- 5. INVALID DISCOUNTS
-- ============================================================

SELECT
    COUNT(*) AS invalid_discount_rows
FROM sales_cleaned
WHERE discount_pct < 0
   OR discount_pct > 1;


-- 6. INVALID PROMOTION DISCOUNTS
-- ============================================================

SELECT
    COUNT(*) AS invalid_promotion_discount_rows
FROM promotions
WHERE discount_pct < 0
   OR discount_pct > 1;


-- 7. INVALID PROMOTION DATE RANGES
-- ============================================================

SELECT
    promotion_id,
    start_date,
    end_date
FROM promotions
WHERE end_date < start_date;


-- 8. SALES WITH UNKNOWN PRODUCTS
-- ============================================================

SELECT
    COUNT(*) AS unmatched_product_rows
FROM sales_cleaned s
LEFT JOIN dim_product p
    ON s.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 9. SALES WITH UNKNOWN STORES
-- ============================================================

SELECT
    COUNT(*) AS unmatched_store_rows
FROM sales_cleaned s
LEFT JOIN dim_store st
    ON s.store_id = st.store_id
WHERE st.store_id IS NULL;


-- 10. SALES WITH UNKNOWN DATES
-- ============================================================

SELECT
    COUNT(*) AS unmatched_date_rows
FROM sales_cleaned s
LEFT JOIN dim_date d
    ON s.`date` = d.`date`
WHERE d.`date` IS NULL;


-- 11. PROMOTIONS WITH UNKNOWN PRODUCTS
-- ============================================================

SELECT
    COUNT(*) AS unmatched_promotion_product_rows
FROM promotions pr
LEFT JOIN dim_product p
    ON pr.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 12. STORE EXPENSES WITH UNKNOWN STORES
-- ============================================================

SELECT
    COUNT(*) AS unmatched_expense_store_rows
FROM store_expenses e
LEFT JOIN dim_store s
    ON e.store_id = s.store_id
WHERE s.store_id IS NULL;


-- 13. SALES DATE RANGE
-- ============================================================

SELECT
    MIN(`date`) AS earliest_date,
    MAX(`date`) AS latest_date
FROM sales_cleaned;


-- 14. EXPENSE DATE RANGE
-- ============================================================

SELECT
    MIN(`date`) AS earliest_date,
    MAX(`date`) AS latest_date
FROM store_expenses;


-- 15. TRANSACTION TYPE DISTRIBUTION
-- ============================================================

SELECT
    transaction_type,
    COUNT(*) AS transaction_count
FROM sales_cleaned
GROUP BY transaction_type
ORDER BY transaction_count DESC;


-- 16. PRICE QUALITY FLAG DISTRIBUTION
-- ============================================================

SELECT
    price_data_quality_flag,
    COUNT(*) AS row_count
FROM sales_cleaned
GROUP BY price_data_quality_flag
ORDER BY row_count DESC;


-- ============================================================
-- 17. NET REVENUE RECONCILIATION
-- ============================================================

SELECT
    ROUND(
        SUM(
            quantity * unit_price *
            (1 - discount_pct)
        ),
        2
    ) AS calculated_net_revenue,

    ROUND(
        SUM(net_revenue),
        2
    ) AS stored_net_revenue,

    ROUND(
        SUM(
            quantity * unit_price *
            (1 - discount_pct)
        )
        - SUM(net_revenue),
        2
    ) AS difference

FROM sales_cleaned

WHERE unit_price IS NOT NULL;

-- ============================================================
-- 18. STORE EXPENSE COVERAGE
-- ============================================================

SELECT
    COUNT(DISTINCT store_id) AS stores,
    COUNT(
        DISTINCT DATE_FORMAT(`date`, '%Y-%m')
    ) AS months,
    COUNT(*) AS records
FROM store_expenses;

SELECT
    MIN(`date`) AS first_month,
    MAX(`date`) AS last_month
FROM store_expenses;

-- ============================================================
-- 19. OPERATING COST RECONCILIATION
-- ============================================================

SELECT
    COUNT(*) AS rows_checked,

    SUM(
        CASE
            WHEN ROUND(
                rent + utilities + labor + other_costs,
                2
            ) <> ROUND(operating_cost, 2)
            THEN 1
            ELSE 0
        END
    ) AS operating_cost_errors

FROM store_expenses;

SELECT
    COUNT(*) AS rows_checked,

    SUM(
        CASE
            WHEN ROUND(
                rent + utilities + other_costs,
                2
            ) <> ROUND(non_labour_cost, 2)
            THEN 1
            ELSE 0
        END
    ) AS non_labour_cost_errors

FROM store_expenses;

