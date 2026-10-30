USE global_retail;

-- ============================================================
-- 04_PROMOTION_EFFECTIVENESS
-- ============================================================

-- ============================================================
-- QUERY 1: PROMOTION COVERAGE AND INTEGRITY
-- ============================================================

SELECT
    COUNT(*) AS total_promotions,

    SUM(
        CASE
            WHEN promotion_duration_days > 0 THEN 1
            ELSE 0
        END
    ) AS valid_duration_promotions,

    SUM(
        CASE
            WHEN start_date <= end_date THEN 1
            ELSE 0
        END
    ) AS valid_date_promotions,

    SUM(
        CASE
            WHEN discount_pct > 0 THEN 1
            ELSE 0
        END
    ) AS discounted_promotions,

    COUNT(DISTINCT product_id) AS products_with_promotions,

    MIN(start_date) AS first_promotion_date,

    MAX(end_date) AS last_promotion_date

FROM promotions;

-- ============================================================
-- QUERY 2: PROMOTION BASELINE VS PROMOTION-PERIOD VOLUME
-- ============================================================

WITH promotion_metrics AS (
    SELECT
        p.promotion_id,
        p.product_id,
        p.discount_pct,
        p.start_date,
        p.end_date,
        p.promotion_duration_days,

        SUM(
            CASE
                WHEN s.date >= p.start_date
                 AND s.date <= p.end_date
                THEN s.quantity
                ELSE 0
            END
        ) AS promotion_volume,

        SUM(
            CASE
                WHEN s.date >= DATE_SUB(
                    p.start_date,
                    INTERVAL p.promotion_duration_days DAY
                )
                AND s.date < p.start_date
                THEN s.quantity
                ELSE 0
            END
        ) AS baseline_volume

    FROM promotions p

    LEFT JOIN sales_cleaned s
        ON s.product_id = p.product_id
        AND s.date >= DATE_SUB(
            p.start_date,
            INTERVAL p.promotion_duration_days DAY
        )
        AND s.date <= p.end_date

    GROUP BY
        p.promotion_id,
        p.product_id,
        p.discount_pct,
        p.start_date,
        p.end_date,
        p.promotion_duration_days
)

SELECT
    promotion_id,
    product_id,
    discount_pct,
    start_date,
    end_date,
    promotion_duration_days,

    baseline_volume,

    promotion_volume,

    ROUND(
        baseline_volume /
        NULLIF(promotion_duration_days, 0),
        2
    ) AS baseline_daily_quantity,

    ROUND(
        promotion_volume /
        NULLIF(promotion_duration_days, 0),
        2
    ) AS promotion_daily_quantity,

    ROUND(
        (
            promotion_volume /
            NULLIF(promotion_duration_days, 0)
        )
        -
        (
            baseline_volume /
            NULLIF(promotion_duration_days, 0)
        ),
        2
    ) AS observed_daily_lift

FROM promotion_metrics

ORDER BY
    observed_daily_lift DESC;

-- ============================================================
-- QUERY 3: OBSERVED LIFT AND ESTIMATED INCREMENTAL UNITS
-- ============================================================

WITH promotion_volume AS (
    SELECT
        p.promotion_id,
        p.product_id,
        p.discount_pct,
        p.start_date,
        p.end_date,
        p.promotion_duration_days,

        SUM(
            CASE
                WHEN s.date >= p.start_date
                 AND s.date <= p.end_date
                THEN s.quantity
                ELSE 0
            END
        ) AS promotion_volume,

        SUM(
            CASE
                WHEN s.date >= DATE_SUB(
                    p.start_date,
                    INTERVAL p.promotion_duration_days DAY
                )
                AND s.date < p.start_date
                THEN s.quantity
                ELSE 0
            END
        ) AS baseline_volume

    FROM promotions p

    LEFT JOIN sales_cleaned s
        ON s.product_id = p.product_id
        AND s.date >= DATE_SUB(
            p.start_date,
            INTERVAL p.promotion_duration_days DAY
        )
        AND s.date <= p.end_date

    GROUP BY
        p.promotion_id,
        p.product_id,
        p.discount_pct,
        p.start_date,
        p.end_date,
        p.promotion_duration_days
),

calculated AS (
    SELECT
        promotion_id,
        product_id,
        discount_pct,
        promotion_duration_days,

        baseline_volume,
        promotion_volume,

        baseline_volume /
            NULLIF(promotion_duration_days, 0)
            AS baseline_daily_quantity,

        promotion_volume /
            NULLIF(promotion_duration_days, 0)
            AS promotion_daily_quantity

    FROM promotion_volume
)

SELECT
    promotion_id,
    product_id,
    discount_pct,
    promotion_duration_days,

    baseline_volume,
    promotion_volume,

    ROUND(
        baseline_daily_quantity,
        2
    ) AS baseline_daily_quantity,

    ROUND(
        promotion_daily_quantity,
        2
    ) AS promotion_daily_quantity,

    CASE
        WHEN baseline_daily_quantity <= 0 THEN NULL

        ELSE ROUND(
            (
                promotion_daily_quantity /
                NULLIF(baseline_daily_quantity, 0)
            ) - 1,
            4
        )
    END AS observed_lift_pct,

    ROUND(
        promotion_volume
        -
        (
            baseline_daily_quantity
            * promotion_duration_days
        ),
        2
    ) AS estimated_incremental_units

FROM calculated

ORDER BY
    estimated_incremental_units DESC;

-- ============================================================
-- QUERY 4: DISCOUNT VALUE OBSERVED DURING PROMOTION WINDOWS
-- ============================================================

SELECT
    p.promotion_id,
    p.product_id,

    p.discount_pct AS planned_discount_pct,

    p.start_date,
    p.end_date,
    p.promotion_duration_days,

    COUNT(s.order_id) AS transaction_count,

    COALESCE(
        SUM(s.quantity),
        0
    ) AS promotion_volume,

    COALESCE(
        SUM(s.discount_value),
        0
    ) AS discount_value_observed,

    CASE
        WHEN EXISTS (
            SELECT 1
            FROM promotions p2
            WHERE
                p2.product_id = p.product_id
                AND p2.promotion_id <> p.promotion_id
                AND p2.start_date <= p.end_date
                AND p2.end_date >= p.start_date
        )
        THEN 'Yes'
        ELSE 'No'
    END AS overlap_flag

FROM promotions p

LEFT JOIN sales_cleaned s
    ON s.product_id = p.product_id
    AND s.date >= p.start_date
    AND s.date <= p.end_date

GROUP BY
    p.promotion_id,
    p.product_id,
    p.discount_pct,
    p.start_date,
    p.end_date,
    p.promotion_duration_days

ORDER BY
    discount_value_observed DESC;

-- ============================================================
-- QUERY 5: PROMOTION EFFECTIVENESS SCORECARD
-- ============================================================

WITH promotion_metrics AS (
    SELECT
        p.promotion_id,
        p.product_id,
        p.discount_pct,
        p.start_date,
        p.end_date,
        p.promotion_duration_days,

        -- Promotion-period volume
        SUM(
            CASE
                WHEN s.date >= p.start_date
                 AND s.date <= p.end_date
                THEN s.quantity
                ELSE 0
            END
        ) AS promotion_volume,

        -- Fixed 30-day pre-promotion baseline
        SUM(
            CASE
                WHEN s.date >= DATE_SUB(
                    p.start_date,
                    INTERVAL 30 DAY
                )
                AND s.date < p.start_date
                THEN s.quantity
                ELSE 0
            END
        ) AS baseline_volume,

        -- Actual discount value recorded during
        -- the promotion window
        SUM(
            CASE
                WHEN s.date >= p.start_date
                 AND s.date <= p.end_date
                THEN s.discount_value
                ELSE 0
            END
        ) AS discount_value_observed

    FROM promotions p

    LEFT JOIN sales_cleaned s
        ON s.product_id = p.product_id
        AND s.date >= DATE_SUB(
            p.start_date,
            INTERVAL 30 DAY
        )
        AND s.date <= p.end_date

    GROUP BY
        p.promotion_id,
        p.product_id,
        p.discount_pct,
        p.start_date,
        p.end_date,
        p.promotion_duration_days
),

calculated AS (
    SELECT
        *,

        -- 30-day baseline daily volume
        baseline_volume / 30.0
            AS baseline_daily_quantity,

        -- Actual daily promotion volume
        promotion_volume /
            NULLIF(promotion_duration_days, 0)
            AS promotion_daily_quantity,

        -- Observed lift percentage
        CASE
            WHEN baseline_volume <= 0 THEN NULL

            ELSE
                (
                    promotion_volume /
                    NULLIF(promotion_duration_days, 0)
                )
                /
                NULLIF(
                    baseline_volume / 30.0,
                    0
                ) - 1
        END AS observed_lift_pct,

        -- Estimated incremental units
        promotion_volume
        -
        (
            (
                baseline_volume / 30.0
            )
            * promotion_duration_days
        ) AS estimated_incremental_units,

        -- Check whether another promotion overlaps
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM promotions p2
                WHERE
                    p2.product_id = promotion_metrics.product_id
                    AND p2.promotion_id <> promotion_metrics.promotion_id
                    AND p2.start_date <= promotion_metrics.end_date
                    AND p2.end_date >= promotion_metrics.start_date
            )
            THEN 'Yes'
            ELSE 'No'
        END AS overlap_flag

    FROM promotion_metrics
),

final_metrics AS (
    SELECT
        *,

        -- Discount cost per estimated incremental unit
        CASE
            WHEN discount_value_observed > 0
                 AND estimated_incremental_units > 0
            THEN
                discount_value_observed /
                estimated_incremental_units
            ELSE NULL
        END AS cost_per_incremental_unit

    FROM calculated
)

SELECT
    promotion_id,
    product_id,
    discount_pct,
    promotion_duration_days,

    ROUND(
        baseline_daily_quantity,
        2
    ) AS baseline_daily_quantity,

    ROUND(
        promotion_daily_quantity,
        2
    ) AS promotion_daily_quantity,

    ROUND(
        observed_lift_pct,
        4
    ) AS observed_lift_pct,

    ROUND(
        estimated_incremental_units,
        2
    ) AS estimated_incremental_units,

    ROUND(
        discount_value_observed,
        2
    ) AS discount_value_observed,

    ROUND(
        cost_per_incremental_unit,
        2
    ) AS cost_per_incremental_unit,

    overlap_flag,

    CASE

        WHEN baseline_volume <= 0
            THEN 'Insufficient Baseline'

        WHEN estimated_incremental_units <= 0
            THEN 'Negative / No Observed Lift'

        WHEN overlap_flag = 'Yes'
            THEN 'Overlapping Promotion'

        WHEN discount_value_observed <= 0
            THEN 'Positive Lift / No Realized Discount'

        WHEN observed_lift_pct >= 0.20
             AND cost_per_incremental_unit <= 10
            THEN 'High Lift / Low Cost'

        WHEN observed_lift_pct >= 0.20
            THEN 'High Lift / High Cost'

        WHEN cost_per_incremental_unit <= 10
            THEN 'Low Lift / Low Cost'

        ELSE 'Low Lift / High Cost'

    END AS promotion_classification

FROM final_metrics

ORDER BY
    estimated_incremental_units DESC;
    
-- ============================================================
-- QUERY 6: PROMOTION OVERLAP DIAGNOSTIC
-- ============================================================

SELECT
    p1.promotion_id AS promotion_1,
    p2.promotion_id AS promotion_2,

    p1.product_id,

    p1.start_date AS promotion_1_start,
    p1.end_date AS promotion_1_end,

    p2.start_date AS promotion_2_start,
    p2.end_date AS promotion_2_end

FROM promotions p1

JOIN promotions p2
    ON p1.product_id = p2.product_id
    AND p1.promotion_id < p2.promotion_id

WHERE
    p1.start_date <= p2.end_date
    AND p2.start_date <= p1.end_date

ORDER BY
    p1.product_id,
    p1.start_date;

-- ============================================================
-- QUERY 7: OVERLAP CHECK (expected result: 14 promotions)
-- Compare with the number of 'Yes' in overlap_flag in Query 5.
-- ============================================================

SELECT
    COUNT(DISTINCT p1.promotion_id) AS promotions_with_overlap
FROM promotions p1
JOIN promotions p2
    ON p1.product_id = p2.product_id
    AND p1.promotion_id <> p2.promotion_id
WHERE
    p2.start_date <= p1.end_date
    AND p2.end_date >= p1.start_date;

-- ============================================================
-- QUERY 8: POOLED LIFT - DISCOUNT REALIZED VS NOT REALIZED
-- Pooled lift = total promo daily units / total baseline daily units - 1
-- (not the average of percentages, which one tiny baseline distorts)
-- ============================================================

WITH promo AS (
    SELECT
        p.promotion_id,
        p.promotion_duration_days AS duration_days,
        SUM(CASE WHEN s.`date` BETWEEN p.start_date AND p.end_date
                 THEN s.quantity ELSE 0 END) AS promo_units,
        SUM(CASE WHEN s.`date` >= DATE_SUB(p.start_date, INTERVAL 30 DAY)
                  AND s.`date` <  p.start_date
                 THEN s.quantity ELSE 0 END) AS baseline_units,
        SUM(CASE WHEN s.`date` BETWEEN p.start_date AND p.end_date
                 THEN COALESCE(s.discount_value, 0) ELSE 0 END) AS discount_value
    FROM promotions p
    LEFT JOIN sales_cleaned s
        ON s.product_id = p.product_id
        AND s.`date` BETWEEN DATE_SUB(p.start_date, INTERVAL 30 DAY) AND p.end_date
    GROUP BY p.promotion_id, p.promotion_duration_days
)
SELECT
    CASE WHEN discount_value > 0 THEN 'Discount realized'
         ELSE 'Logged, no discount' END AS promotion_group,
    COUNT(*) AS promotions,
    ROUND(SUM(promo_units / duration_days) / SUM(baseline_units / 30.0) - 1, 4) AS pooled_lift,
    ROUND(SUM(discount_value), 0) AS discount_value
FROM promo
GROUP BY CASE WHEN discount_value > 0 THEN 'Discount realized'
              ELSE 'Logged, no discount' END
UNION ALL
SELECT
    'ALL 130 PROMOTIONS',
    COUNT(*),
    ROUND(SUM(promo_units / duration_days) / SUM(baseline_units / 30.0) - 1, 4),
    ROUND(SUM(discount_value), 0)
FROM promo;

-- ============================================================
-- QUERY 9: THE MEASUREMENT GAP
-- Where does realized discount value sit relative to logged promo
-- windows? (2024-2025, rows with a valid price)
-- ============================================================

SELECT
    in_promo_window,
    COUNT(*) AS sales_lines,
    SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END) AS discounted_lines,
    ROUND(SUM(discount_value), 0) AS discount_value,
    ROUND(SUM(discount_value) / SUM(SUM(discount_value)) OVER (), 4) AS share_of_discount_value
FROM (
    SELECT
        s.discount_pct,
        s.discount_value,
        CASE WHEN EXISTS (
                SELECT 1
                FROM promotions p
                WHERE p.product_id = s.product_id
                  AND s.`date` BETWEEN p.start_date AND p.end_date
             ) THEN 1 ELSE 0 END AS in_promo_window
    FROM sales_cleaned s
    WHERE s.unit_price IS NOT NULL
      AND s.`year` IN (2024, 2025)
) x
GROUP BY in_promo_window;