-- =========================================================
-- 15 Business Diagnostics
-- ---------------------------------------------------------
-- Purpose:
-- Integrate growth, customer, product, seller,
-- fulfillment, experience and geographic analysis
-- into cross-domain diagnostic evidence chains.
--
-- Principle:
-- Association does not imply causality.
-- Findings should distinguish facts, associations,
-- hypotheses and recommended actions.
-- =========================================================

CREATE VIEW vw_month_calendar AS

WITH RECURSIVE date_bounds AS (

    SELECT
        CAST(
            DATE_FORMAT(
                MIN(order_purchase_timestamp),
                '%Y-%m-01'
            ) AS DATE
        ) AS min_month,

        CAST(
            DATE_FORMAT(
                MAX(order_purchase_timestamp),
                '%Y-%m-01'
            ) AS DATE
        ) AS max_month

    FROM vw_order_fact

    WHERE order_status = 'delivered'

),

month_series AS (

    SELECT
        min_month AS month_start,
        max_month
    FROM date_bounds

    UNION ALL

    SELECT
        DATE_ADD(month_start, INTERVAL 1 MONTH),
        max_month
    FROM month_series
    WHERE month_start < max_month
)

SELECT
    month_start
FROM month_series;



DROP VIEW IF EXISTS vw_diagnostic_monthly;

CREATE VIEW vw_diagnostic_monthly AS

SELECT
    g.month,

    -- Business Growth
    g.merchandise_gmv,
    g.orders,
    g.customers,
    g.aov,

    g.gmv_growth_pct,
    g.order_growth_pct,
    g.customer_growth_pct,
    g.aov_growth_pct,

    -- Customer Structure
    g.new_customers,
    g.returning_customers,

    g.new_customer_gmv,
    g.returning_customer_gmv,

    g.new_customer_gmv_share,
    g.returning_customer_gmv_share,

    -- Fulfillment
    f.avg_delivery_days,
    f.avg_promised_delivery_days,
    f.late_rate,

    -- Experience
    e.avg_review_score,
    e.low_rating_rate,
    e.positive_rating_rate

FROM vw_growth_dashboard g

LEFT JOIN vw_fulfillment_monthly f
    ON g.month = f.month

LEFT JOIN vw_experience_monthly e
    ON g.month = e.month;



SELECT
    month,

    merchandise_gmv,

    gmv_growth_pct,
    order_growth_pct,
    customer_growth_pct,
    aov_growth_pct,

    CASE

        WHEN gmv_growth_pct IS NULL
        THEN 'No Prior Comparison'

        WHEN gmv_growth_pct > 0
         AND order_growth_pct > 0
         AND aov_growth_pct > 0
        THEN 'Orders & AOV Both Positive'

        WHEN gmv_growth_pct > 0
         AND order_growth_pct > 0
         AND aov_growth_pct <= 0
        THEN 'Volume-Expansion Pattern'

        WHEN gmv_growth_pct > 0
         AND order_growth_pct <= 0
         AND aov_growth_pct > 0
        THEN 'Higher-AOV Pattern'

        WHEN gmv_growth_pct < 0
        THEN 'Contraction'

        ELSE 'Mixed'

    END AS growth_pattern

FROM vw_diagnostic_monthly

ORDER BY month;



SELECT
    month,

    merchandise_gmv,

    gmv_growth_pct,
    order_growth_pct,
    customer_growth_pct,
    aov_growth_pct,

    CASE

        WHEN gmv_growth_pct IS NULL
        THEN 'No Prior Comparison'

        WHEN gmv_growth_pct > 0
         AND order_growth_pct > 0
         AND aov_growth_pct > 0
        THEN 'Orders & AOV Both Positive'

        WHEN gmv_growth_pct > 0
         AND order_growth_pct > 0
         AND aov_growth_pct <= 0
        THEN 'Volume-Expansion Pattern'

        WHEN gmv_growth_pct > 0
         AND order_growth_pct <= 0
         AND aov_growth_pct > 0
        THEN 'Higher-AOV Pattern'

        WHEN gmv_growth_pct < 0
        THEN 'Contraction'

        ELSE 'Mixed'

    END AS growth_pattern

FROM vw_diagnostic_monthly

ORDER BY month;




SELECT
    month,

    orders,
    order_growth_pct,
    merchandise_gmv,
    gmv_growth_pct,

    avg_delivery_days,
    late_rate,

    avg_review_score,
    low_rating_rate

FROM vw_diagnostic_monthly

WHERE order_growth_pct > 0

ORDER BY order_growth_pct DESC;




WITH x AS (

    SELECT
        *,

        LAG(late_rate)
        OVER (ORDER BY month)
            AS previous_late_rate,

        LAG(low_rating_rate)
        OVER (ORDER BY month)
            AS previous_low_rating_rate

    FROM vw_diagnostic_monthly
)

SELECT
    month,

    order_growth_pct,

    ROUND(
        late_rate - previous_late_rate,
        2
    ) AS late_rate_change_pp,

    ROUND(
        low_rating_rate
        - previous_low_rating_rate,
        2
    ) AS low_rating_rate_change_pp

FROM x

WHERE order_growth_pct IS NOT NULL

ORDER BY month;




CREATE VIEW vw_customer_value_diagnostic AS

WITH customer_metrics AS (

    SELECT
        COUNT(*) AS total_customers,

        SUM(
            CASE
                WHEN order_count >= 2
                THEN 1 ELSE 0
            END
        ) AS repeat_customers,

        SUM(
            CASE
                WHEN order_count = 1
                THEN lifetime_merchandise_value
                ELSE 0
            END
        ) AS one_time_gmv,

        SUM(
            CASE
                WHEN order_count >= 2
                THEN lifetime_merchandise_value
                ELSE 0
            END
        ) AS repeat_gmv,

        AVG(
            CASE
                WHEN order_count = 1
                THEN lifetime_merchandise_value
            END
        ) AS one_time_avg_value,

        AVG(
            CASE
                WHEN order_count >= 2
                THEN lifetime_merchandise_value
            END
        ) AS repeat_avg_value,

        SUM(lifetime_merchandise_value)
            AS total_gmv

    FROM vw_customer_intelligence
)

SELECT
    total_customers,
    repeat_customers,

    ROUND(
        repeat_customers * 100.0
        / NULLIF(total_customers, 0),
        2
    ) AS descriptive_repeat_customer_rate,

    ROUND(
        repeat_gmv * 100.0
        / NULLIF(total_gmv, 0),
        2
    ) AS repeat_customer_gmv_share,

    ROUND(
        repeat_avg_value,
        2
    ) AS repeat_avg_customer_value,

    ROUND(
        one_time_avg_value,
        2
    ) AS one_time_avg_customer_value,

    ROUND(
        repeat_avg_value
        / NULLIF(one_time_avg_value, 0),
        2
    ) AS repeat_value_multiple

FROM customer_metrics;



SELECT
    cohort_index,

    COUNT(*) AS eligible_cohorts,

    SUM(cohort_size) AS eligible_original_customers,

    SUM(active_customers) AS active_customers,

    ROUND(
        SUM(active_customers) * 100.0
        /
        NULLIF(SUM(cohort_size), 0),
        2
    ) AS weighted_retention_rate

FROM vw_cohort_retention

WHERE cohort_index IN (1, 3, 6)

GROUP BY cohort_index

ORDER BY cohort_index;



SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS historical_gmv,

    ROUND(
        SUM(monetary_value) * 100.0
        /
        SUM(
            SUM(monetary_value)
        ) OVER (),
        2
    ) AS historical_gmv_share,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_frequency

FROM vw_rfm_segments

GROUP BY customer_segment

ORDER BY historical_gmv DESC;




SELECT
    COUNT(*) AS at_risk_customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS at_risk_historical_gmv,

    ROUND(
        SUM(monetary_value) * 100.0
        /
        (
            SELECT SUM(monetary_value)
            FROM vw_rfm_segments
        ),
        2
    ) AS at_risk_historical_gmv_share

FROM vw_rfm_segments

WHERE customer_segment IN (
    'High-Value At Risk',
    'Cannot Lose Them'
);




SELECT
    delay_severity,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL
  AND delay_severity <> 'Unknown'

GROUP BY delay_severity

ORDER BY
    CASE delay_severity
        WHEN 'Not Late' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8-14 Days Late' THEN 4
        WHEN '15+ Days Late' THEN 5
    END;





SELECT
    delay_severity,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL
  AND delay_severity <> 'Unknown'

GROUP BY delay_severity

ORDER BY
    CASE delay_severity
        WHEN 'Not Late' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8-14 Days Late' THEN 4
        WHEN '15+ Days Late' THEN 5
    END;





SELECT
    delay_severity,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL
  AND delay_severity <> 'Unknown'

GROUP BY delay_severity

ORDER BY
    CASE delay_severity
        WHEN 'Not Late' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8-14 Days Late' THEN 4
        WHEN '15+ Days Late' THEN 5
    END;





CREATE VIEW vw_category_diagnostic AS

WITH experience AS (

    SELECT
        product_category,

        COUNT(*) AS reviewed_orders,

        AVG(review_score)
            AS avg_review_score,

        AVG(is_low_rating) * 100
            AS low_rating_rate,

        AVG(
            CASE
                WHEN delivery_status = 'Late'
                THEN 1
                ELSE 0
            END
        ) * 100 AS delay_rate

    FROM vw_order_category_experience

    GROUP BY product_category
)

SELECT
    p.product_category,

    p.orders,
    p.customers,

    p.merchandise_gmv,
    p.freight_value,
    p.freight_to_gmv_pct,

    a.abc_class,
    a.gmv_share_pct,
    a.cumulative_gmv_share_pct,

    ROUND(
        e.avg_review_score,
        2
    ) AS avg_review_score,

    ROUND(
        e.low_rating_rate,
        2
    ) AS low_rating_rate,

    ROUND(
        e.delay_rate,
        2
    ) AS delay_rate,

    e.reviewed_orders

FROM vw_category_performance p

LEFT JOIN vw_category_abc a
    ON p.product_category =
       a.product_category

LEFT JOIN experience e
    ON p.product_category =
       e.product_category;



SELECT
    product_category,

    merchandise_gmv,
    gmv_share_pct,

    orders,
    customers,

    freight_to_gmv_pct,

    avg_review_score,
    low_rating_rate,
    delay_rate

FROM vw_category_diagnostic

WHERE abc_class = 'A - Core'

ORDER BY merchandise_gmv DESC;





CREATE VIEW vw_seller_diagnostic AS

SELECT
    c.seller_id,
    c.seller_state,

    c.orders,
    c.customers,
    c.merchandise_gmv,

    e.avg_review_score,
    e.low_rating_rate,

    f.delay_rate,
    f.avg_delivery_days,

    d.late_dispatch_rate,
    d.avg_hours_vs_deadline

FROM vw_seller_commercial c

LEFT JOIN vw_seller_experience_latest e
    ON c.seller_id = e.seller_id

LEFT JOIN vw_seller_fulfillment f
    ON c.seller_id = f.seller_id

LEFT JOIN vw_seller_dispatch d
    ON c.seller_id = d.seller_id;



WITH ranked AS (

    SELECT
        *,

        PERCENT_RANK() OVER (
            ORDER BY merchandise_gmv
        ) AS gmv_pct,

        PERCENT_RANK() OVER (
            ORDER BY low_rating_rate
        ) AS low_rating_pct,

        PERCENT_RANK() OVER (
            ORDER BY delay_rate
        ) AS delay_pct,

        PERCENT_RANK() OVER (
            ORDER BY late_dispatch_rate
        ) AS dispatch_pct

    FROM vw_seller_diagnostic

    WHERE orders >= 50
      AND low_rating_rate IS NOT NULL
      AND delay_rate IS NOT NULL
)

SELECT
    seller_id,

    orders,
    merchandise_gmv,

    avg_review_score,
    low_rating_rate,
    delay_rate,
    late_dispatch_rate,

    CASE
        WHEN gmv_pct >= 0.75
         AND (
              low_rating_pct >= 0.75
              OR delay_pct >= 0.75
              OR dispatch_pct >= 0.75
         )
        THEN 'High-Value Seller Attention'

        ELSE 'No Priority Flag'
    END AS seller_priority_flag

FROM ranked

ORDER BY merchandise_gmv DESC;




WITH ranked AS (

    SELECT
        *,

        PERCENT_RANK() OVER (
            ORDER BY merchandise_gmv
        ) AS gmv_pct,

        PERCENT_RANK() OVER (
            ORDER BY low_rating_rate
        ) AS low_rating_pct,

        PERCENT_RANK() OVER (
            ORDER BY delay_rate
        ) AS delay_pct,

        PERCENT_RANK() OVER (
            ORDER BY late_dispatch_rate
        ) AS dispatch_pct

    FROM vw_seller_diagnostic

    WHERE orders >= 50
      AND low_rating_rate IS NOT NULL
      AND delay_rate IS NOT NULL
)

SELECT
    seller_id,

    orders,
    merchandise_gmv,

    avg_review_score,
    low_rating_rate,
    delay_rate,
    late_dispatch_rate,

    CASE
        WHEN gmv_pct >= 0.75
         AND (
              low_rating_pct >= 0.75
              OR delay_pct >= 0.75
              OR dispatch_pct >= 0.75
         )
        THEN 'High-Value Seller Attention'

        ELSE 'No Priority Flag'
    END AS seller_priority_flag

FROM ranked

ORDER BY merchandise_gmv DESC;





CREATE VIEW vw_state_diagnostic AS

SELECT
    *,

    PERCENT_RANK() OVER (
        ORDER BY customer_demand_gmv
    ) AS demand_value_percentile,

    PERCENT_RANK() OVER (
        ORDER BY delay_rate
    ) AS delay_percentile,

    PERCENT_RANK() OVER (
        ORDER BY low_rating_rate
    ) AS low_rating_percentile,

    PERCENT_RANK() OVER (
        ORDER BY freight_to_gmv_pct
    ) AS freight_percentile

FROM vw_state_market_dashboard

WHERE customer_orders >= 100;




SELECT
    state_code,

    customer_orders,
    customers,

    customer_demand_gmv,
    demand_gmv_share_pct,

    freight_to_gmv_pct,
    avg_delivery_days,
    delay_rate,
    avg_review_score,
    low_rating_rate,

    supply_demand_share_gap_pp,

    CASE

        WHEN demand_value_percentile >= 0.75
         AND (
             delay_percentile >= 0.75
             OR low_rating_percentile >= 0.75
             OR freight_percentile >= 0.75
         )
        THEN 'Core Market Operational Attention'

        ELSE 'No Priority Flag'
    END AS regional_priority_flag

FROM vw_state_diagnostic

ORDER BY customer_demand_gmv DESC;



SELECT
    geographic_relation,

    COUNT(*) AS orders,

    ROUND(
        AVG(straight_line_distance_km),
        2
    ) AS avg_distance_km,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(is_delayed) * 100,
        2
    ) AS delay_rate,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score

FROM vw_single_seller_order_distance

GROUP BY geographic_relation;