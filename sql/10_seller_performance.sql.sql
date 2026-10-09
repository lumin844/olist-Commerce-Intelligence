-- =========================================================
-- 10 Seller Performance Intelligence
-- ---------------------------------------------------------
-- Purpose:
-- Evaluate seller commercial contribution, customer reach,
-- fulfillment quality and customer experience, and identify
-- high-value, high-risk and growth sellers.
-- =========================================================
CREATE VIEW vw_order_seller AS

SELECT
    oi.order_id,
    oi.seller_id,

    f.customer_unique_id,
    f.order_status,
    f.order_purchase_timestamp,
    f.purchase_year_month,

    s.seller_city,
    s.seller_state,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.product_id)
        AS distinct_products,

    ROUND(
        SUM(oi.price),
        2
    ) AS seller_merchandise_gmv,

    ROUND(
        SUM(oi.freight_value),
        2
    ) AS seller_freight_value,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS seller_gross_value,

    MAX(oi.shipping_limit_date)
        AS seller_shipping_deadline,

    f.order_delivered_carrier_date,
    f.order_delivered_customer_date,
    f.order_estimated_delivery_date,

    f.delivery_days,
    f.delay_days,
    f.is_delayed,

    f.avg_review_score

FROM order_items oi

INNER JOIN vw_order_fact f
    ON oi.order_id = f.order_id

LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id

GROUP BY
    oi.order_id,
    oi.seller_id,
    f.customer_unique_id,
    f.order_status,
    f.order_purchase_timestamp,
    f.purchase_year_month,
    s.seller_city,
    s.seller_state,
    f.order_delivered_carrier_date,
    f.order_delivered_customer_date,
    f.order_estimated_delivery_date,
    f.delivery_days,
    f.delay_days,
    f.is_delayed,
    f.avg_review_score;



CREATE VIEW vw_seller_commercial AS

SELECT
    seller_id,

    MAX(seller_city) AS seller_city,
    MAX(seller_state) AS seller_state,

    COUNT(DISTINCT order_id)
        AS orders,

    COUNT(DISTINCT customer_unique_id)
        AS customers,

    SUM(units_sold)
        AS units_sold,

    SUM(distinct_products)
        AS product_lines_sold,

    ROUND(
        SUM(seller_merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(seller_freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(seller_gross_value),
        2
    ) AS gross_value,

    ROUND(
        SUM(seller_merchandise_gmv)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS gmv_per_order,

    ROUND(
        SUM(seller_merchandise_gmv)
        / NULLIF(COUNT(DISTINCT customer_unique_id), 0),
        2
    ) AS gmv_per_customer,

    ROUND(
        SUM(units_sold) * 1.0
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS units_per_order

FROM vw_order_seller

WHERE order_status = 'delivered'

GROUP BY seller_id;



WITH seller_rank AS (

    SELECT
        seller_id,
        merchandise_gmv,

        merchandise_gmv
        /
        SUM(merchandise_gmv) OVER ()
            AS gmv_share,

        ROW_NUMBER() OVER (
            ORDER BY merchandise_gmv DESC
        ) AS seller_rank

    FROM vw_seller_commercial
),

pareto AS (

    SELECT
        *,

        SUM(gmv_share) OVER (
            ORDER BY seller_rank
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_gmv_share

    FROM seller_rank
)

SELECT
    seller_id,
    seller_rank,

    ROUND(merchandise_gmv, 2)
        AS merchandise_gmv,

    ROUND(gmv_share * 100, 2)
        AS gmv_share_pct,

    ROUND(cumulative_gmv_share * 100, 2)
        AS cumulative_gmv_share_pct

FROM pareto

ORDER BY seller_rank;




WITH ranked AS (

    SELECT
        seller_id,
        merchandise_gmv,

        ROW_NUMBER() OVER (
            ORDER BY merchandise_gmv DESC
        ) AS rn

    FROM vw_seller_commercial
)

SELECT
    ROUND(
        SUM(
            CASE WHEN rn <= 10
                 THEN merchandise_gmv ELSE 0 END
        ) * 100.0
        / SUM(merchandise_gmv),
        2
    ) AS top10_seller_gmv_share,

    ROUND(
        SUM(
            CASE WHEN rn <= 50
                 THEN merchandise_gmv ELSE 0 END
        ) * 100.0
        / SUM(merchandise_gmv),
        2
    ) AS top50_seller_gmv_share,

    ROUND(
        SUM(
            CASE WHEN rn <= 100
                 THEN merchandise_gmv ELSE 0 END
        ) * 100.0
        / SUM(merchandise_gmv),
        2
    ) AS top100_seller_gmv_share

FROM ranked;





CREATE VIEW vw_seller_experience AS

SELECT
    seller_id,

    COUNT(DISTINCT order_id)
        AS orders,

    COUNT(avg_review_score)
        AS reviewed_orders,

    ROUND(
        AVG(avg_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        SUM(
            CASE
                WHEN avg_review_score <= 2
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(avg_review_score), 0),
        2
    ) AS low_rating_rate,

    ROUND(
        SUM(
            CASE
                WHEN avg_review_score >= 4
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(avg_review_score), 0),
        2
    ) AS high_rating_rate

FROM vw_order_seller

WHERE order_status = 'delivered'
  AND avg_review_score IS NOT NULL

GROUP BY seller_id;




CREATE VIEW vw_seller_fulfillment AS

SELECT
    seller_id,

    COUNT(DISTINCT order_id)
        AS delivered_orders,

    COUNT(is_delayed)
        AS orders_with_delivery_status,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(delay_days),
        2
    ) AS avg_delay_days,

    SUM(
        CASE
            WHEN is_delayed = 1
            THEN 1 ELSE 0
        END
    ) AS delayed_orders,

    ROUND(
        SUM(
            CASE
                WHEN is_delayed = 1
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(is_delayed), 0),
        2
    ) AS delay_rate

FROM vw_order_seller

WHERE order_status = 'delivered'

GROUP BY seller_id;



SELECT
    seller_id,

    COUNT(*) AS eligible_orders,

    SUM(
        CASE
            WHEN order_delivered_carrier_date
                 > seller_shipping_deadline
            THEN 1
            ELSE 0
        END
    ) AS late_dispatch_orders,

    ROUND(
        SUM(
            CASE
                WHEN order_delivered_carrier_date
                     > seller_shipping_deadline
                THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_dispatch_rate

FROM vw_order_seller

WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL
  AND seller_shipping_deadline IS NOT NULL

GROUP BY seller_id;





CREATE VIEW vw_seller_dispatch AS

SELECT
    seller_id,

    COUNT(*) AS eligible_orders,

    SUM(
        CASE
            WHEN order_delivered_carrier_date >
                 seller_shipping_deadline
            THEN 1 ELSE 0
        END
    ) AS late_dispatch_orders,

    ROUND(
        SUM(
            CASE
                WHEN order_delivered_carrier_date >
                     seller_shipping_deadline
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(*), 0),
        2
    ) AS late_dispatch_rate,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                HOUR,
                seller_shipping_deadline,
                order_delivered_carrier_date
            )
        ),
        2
    ) AS avg_hours_vs_deadline

FROM vw_order_seller

WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL
  AND seller_shipping_deadline IS NOT NULL

GROUP BY seller_id;





CREATE VIEW vw_seller_performance AS

SELECT
    c.seller_id,
    c.seller_city,
    c.seller_state,

    c.orders,
    c.customers,
    c.units_sold,

    c.merchandise_gmv,
    c.freight_value,
    c.gross_value,

    c.gmv_per_order,
    c.gmv_per_customer,
    c.units_per_order,

    e.avg_review_score,
    e.low_rating_rate,
    e.high_rating_rate,

    f.avg_delivery_days,
    f.avg_delay_days,
    f.delay_rate,

    d.late_dispatch_rate,
    d.avg_hours_vs_deadline

FROM vw_seller_commercial c

LEFT JOIN vw_seller_experience e
    ON c.seller_id = e.seller_id

LEFT JOIN vw_seller_fulfillment f
    ON c.seller_id = f.seller_id

LEFT JOIN vw_seller_dispatch d
    ON c.seller_id = d.seller_id;




WITH benchmark AS (

    SELECT
        AVG(merchandise_gmv)
            AS avg_seller_gmv,

        AVG(avg_review_score)
            AS avg_seller_rating

    FROM vw_seller_performance

    WHERE orders >= 30
      AND avg_review_score IS NOT NULL
)

SELECT
    s.seller_id,
    s.orders,
    s.customers,
    s.merchandise_gmv,
    s.avg_review_score,
    s.low_rating_rate,
    s.delay_rate,
    s.late_dispatch_rate,

    CASE
        WHEN s.merchandise_gmv >= b.avg_seller_gmv
             AND s.avg_review_score >= b.avg_seller_rating
        THEN 'High-Value Reliable'

        WHEN s.merchandise_gmv >= b.avg_seller_gmv
             AND s.avg_review_score < b.avg_seller_rating
        THEN 'Revenue at Risk'

        WHEN s.merchandise_gmv < b.avg_seller_gmv
             AND s.avg_review_score >= b.avg_seller_rating
        THEN 'Growth Potential'

        ELSE 'Low Impact / Improve'

    END AS seller_position

FROM vw_seller_performance s

CROSS JOIN benchmark b

WHERE s.orders >= 30

ORDER BY s.merchandise_gmv DESC;





CREATE VIEW vw_seller_ranked AS

SELECT
    *,

    PERCENT_RANK() OVER (
        ORDER BY merchandise_gmv
    ) AS gmv_percentile,

    PERCENT_RANK() OVER (
        ORDER BY avg_review_score
    ) AS rating_percentile

FROM vw_seller_performance

WHERE orders >= 30
  AND avg_review_score IS NOT NULL;



SELECT
    seller_id,
    merchandise_gmv,
    avg_review_score,

    ROUND(gmv_percentile * 100, 2)
        AS gmv_percentile,

    ROUND(rating_percentile * 100, 2)
        AS rating_percentile

FROM vw_seller_ranked

ORDER BY merchandise_gmv DESC;




SELECT
    seller_id,
    orders,
    merchandise_gmv,
    avg_review_score,
    delay_rate,
    late_dispatch_rate,

    CASE

        WHEN gmv_percentile >= 0.50
             AND rating_percentile >= 0.50
        THEN 'High-Value Reliable'

        WHEN gmv_percentile >= 0.50
             AND rating_percentile < 0.50
        THEN 'Revenue at Risk'

        WHEN gmv_percentile < 0.50
             AND rating_percentile >= 0.50
        THEN 'Growth Potential'

        ELSE 'Low Impact / Improve'

    END AS seller_segment

FROM vw_seller_ranked;




SELECT
    seller_id,

    orders,
    merchandise_gmv,

    avg_review_score,
    low_rating_rate,

    delay_rate,
    late_dispatch_rate

FROM vw_seller_performance

WHERE orders >= 50

ORDER BY
    merchandise_gmv DESC,
    low_rating_rate DESC,
    delay_rate DESC;






CREATE VIEW vw_seller_risk AS

SELECT
    *,

    CASE
        WHEN orders < 30
        THEN 'Insufficient Sample'

        WHEN avg_review_score < 3.5
             AND delay_rate >= 10
        THEN 'High Risk'

        WHEN avg_review_score < 4.0
             OR delay_rate >= 10
             OR late_dispatch_rate >= 10
        THEN 'Watch'

        ELSE 'Stable'
    END AS seller_risk_level

FROM vw_seller_performance;




SELECT
    seller_risk_level,

    COUNT(*) AS sellers,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS gmv,

    ROUND(
        SUM(merchandise_gmv) * 100.0
        /
        SUM(
            SUM(merchandise_gmv)
        ) OVER (),
        2
    ) AS gmv_share_pct

FROM vw_seller_risk

GROUP BY seller_risk_level

ORDER BY gmv DESC;




CREATE VIEW vw_seller_monthly AS

SELECT
    purchase_year_month AS month,
    seller_id,

    COUNT(DISTINCT order_id)
        AS orders,

    COUNT(DISTINCT customer_unique_id)
        AS customers,

    SUM(units_sold)
        AS units_sold,

    ROUND(
        SUM(seller_merchandise_gmv),
        2
    ) AS merchandise_gmv

FROM vw_order_seller

WHERE order_status = 'delivered'

GROUP BY
    purchase_year_month,
    seller_id;



SELECT
    seller_state,

    COUNT(*) AS sellers,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    SUM(orders) AS seller_order_counts

FROM vw_seller_commercial

GROUP BY seller_state

ORDER BY merchandise_gmv DESC;




CREATE VIEW vw_seller_dashboard AS

SELECT
    p.seller_id,
    p.seller_city,
    p.seller_state,

    p.orders,
    p.customers,
    p.units_sold,

    p.merchandise_gmv,
    p.freight_value,
    p.gross_value,

    p.gmv_per_order,
    p.gmv_per_customer,
    p.units_per_order,

    p.avg_review_score,
    p.low_rating_rate,
    p.high_rating_rate,

    p.avg_delivery_days,
    p.avg_delay_days,
    p.delay_rate,

    p.late_dispatch_rate,
    p.avg_hours_vs_deadline,

    r.seller_risk_level

FROM vw_seller_performance p

LEFT JOIN vw_seller_risk r
    ON p.seller_id = r.seller_id;