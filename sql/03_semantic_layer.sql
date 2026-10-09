-- =========================================================
-- Olist Commerce Intelligence 360
-- 03 Semantic Layer
-- ---------------------------------------------------------
-- Purpose:
-- Build standardized analytical views and prevent
-- one-to-many join fanout and metric duplication.
-- =========================================================

CREATE VIEW vw_order_core AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,

    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    DATE(o.order_purchase_timestamp) AS purchase_date,

    YEAR(o.order_purchase_timestamp) AS purchase_year,

    MONTH(o.order_purchase_timestamp) AS purchase_month,

    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS purchase_year_month,

    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,

    CASE
        WHEN o.order_status = 'delivered' THEN 1
        ELSE 0
    END AS is_delivered,

    CASE
        WHEN o.order_status = 'canceled' THEN 1
        ELSE 0
    END AS is_canceled

FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id;

SELECT COUNT(*)
FROM vw_order_core;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_order_core;

CREATE VIEW vw_order_item_summary AS
SELECT
    order_id,

    COUNT(*) AS item_count,

    COUNT(DISTINCT product_id) AS distinct_product_count,

    COUNT(DISTINCT seller_id) AS distinct_seller_count,

    ROUND(SUM(price), 2) AS merchandise_gmv,

    ROUND(SUM(freight_value), 2) AS freight_value,

    ROUND(
        SUM(price) + SUM(freight_value),
        2
    ) AS gross_order_value,

    ROUND(AVG(price), 2) AS avg_item_price,

    MIN(price) AS min_item_price,

    MAX(price) AS max_item_price

FROM order_items
GROUP BY order_id;

SELECT COUNT(*)
FROM vw_order_item_summary;

SELECT
    ROUND(SUM(price), 2) AS raw_item_value,
    ROUND(SUM(freight_value), 2) AS raw_freight_value
FROM order_items;

SELECT
    ROUND(SUM(merchandise_gmv), 2) AS view_item_value,
    ROUND(SUM(freight_value), 2) AS view_freight_value
FROM vw_order_item_summary;

CREATE VIEW vw_payment_summary AS
SELECT
    order_id,

    COUNT(*) AS payment_record_count,

    COUNT(DISTINCT payment_type) AS payment_method_count,

    GROUP_CONCAT(
        DISTINCT payment_type
        ORDER BY payment_type
        SEPARATOR ', '
    ) AS payment_methods,

    ROUND(SUM(payment_value), 2) AS total_payment_value,

    MAX(payment_installments) AS max_installments

FROM payments
GROUP BY order_id;

SELECT
    ROUND(SUM(payment_value), 2)
FROM payments;

SELECT
    ROUND(SUM(total_payment_value), 2)
FROM vw_payment_summary;

CREATE VIEW vw_review_summary AS
SELECT
    order_id,

    COUNT(*) AS review_count,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    MIN(review_score) AS min_review_score,

    MAX(review_score) AS max_review_score,

    MAX(review_creation_date) AS latest_review_date,

    MAX(review_answer_timestamp) AS latest_review_answer_time

FROM reviews
GROUP BY order_id;

CREATE VIEW vw_order_fact AS
SELECT
    oc.order_id,
    oc.customer_id,
    oc.customer_unique_id,

    oc.order_status,

    oc.order_purchase_timestamp,
    oc.order_approved_at,
    oc.order_delivered_carrier_date,
    oc.order_delivered_customer_date,
    oc.order_estimated_delivery_date,

    oc.purchase_date,
    oc.purchase_year,
    oc.purchase_month,
    oc.purchase_year_month,

    oc.customer_zip_code_prefix,
    oc.customer_city,
    oc.customer_state,

    oc.is_delivered,
    oc.is_canceled,

    COALESCE(oi.item_count, 0) AS item_count,

    COALESCE(
        oi.distinct_product_count,
        0
    ) AS distinct_product_count,

    COALESCE(
        oi.distinct_seller_count,
        0
    ) AS distinct_seller_count,

    COALESCE(
        oi.merchandise_gmv,
        0
    ) AS merchandise_gmv,

    COALESCE(
        oi.freight_value,
        0
    ) AS freight_value,

    COALESCE(
        oi.gross_order_value,
        0
    ) AS gross_order_value,

    p.payment_record_count,
    p.payment_method_count,
    p.payment_methods,
    p.total_payment_value,
    p.max_installments,

    r.review_count,
    r.avg_review_score,
    r.min_review_score,
    r.max_review_score,

    CASE
        WHEN oc.order_approved_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            oc.order_purchase_timestamp,
            oc.order_approved_at
        )
    END AS approval_hours,

    CASE
        WHEN oc.order_delivered_carrier_date IS NOT NULL
             AND oc.order_approved_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            oc.order_approved_at,
            oc.order_delivered_carrier_date
        )
    END AS seller_processing_hours,

    CASE
        WHEN oc.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            oc.order_delivered_customer_date,
            oc.order_purchase_timestamp
        )
    END AS delivery_days,

    CASE
        WHEN oc.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            oc.order_delivered_customer_date,
            oc.order_estimated_delivery_date
        )
    END AS delay_days,

    CASE
        WHEN oc.order_delivered_customer_date IS NULL
        THEN NULL

        WHEN oc.order_delivered_customer_date >
             oc.order_estimated_delivery_date
        THEN 1

        ELSE 0
    END AS is_delayed

FROM vw_order_core oc

LEFT JOIN vw_order_item_summary oi
    ON oc.order_id = oi.order_id

LEFT JOIN vw_payment_summary p
    ON oc.order_id = p.order_id

LEFT JOIN vw_review_summary r
    ON oc.order_id = r.order_id;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_order_fact;

CREATE VIEW vw_customer_summary AS
SELECT
    customer_unique_id,

    MIN(order_purchase_timestamp)
        AS first_purchase_time,

    MAX(order_purchase_timestamp)
        AS last_purchase_time,

    COUNT(DISTINCT order_id)
        AS order_count,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS lifetime_merchandise_value,

    ROUND(
        SUM(gross_order_value),
        2
    ) AS lifetime_order_value,

    ROUND(
        AVG(merchandise_gmv),
        2
    ) AS avg_order_value,

    SUM(item_count)
        AS total_items,

    COUNT(DISTINCT purchase_year_month)
        AS active_purchase_months,

    MIN(customer_state)
        AS customer_state

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL

GROUP BY customer_unique_id;

SELECT
    COUNT(*) AS delivered_customers,

    SUM(
        CASE
            WHEN order_count = 1 THEN 1
            ELSE 0
        END
    ) AS one_time_customers,

    SUM(
        CASE
            WHEN order_count >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customers

FROM vw_customer_summary;