-- =========================================================
-- Olist Commerce Intelligence
-- 02 Data Quality Audit
-- Purpose:
-- Check completeness, uniqueness, validity,
-- referential integrity and business logic.
-- =========================================================

SELECT
    COUNT(*) AS total_orders,

    SUM(order_id IS NULL) AS order_id_null,
    SUM(customer_id IS NULL) AS customer_id_null,
    SUM(order_status IS NULL) AS order_status_null,
    SUM(order_purchase_timestamp IS NULL) AS purchase_time_null,
    SUM(order_approved_at IS NULL) AS approved_time_null,
    SUM(order_delivered_carrier_date IS NULL) AS carrier_date_null,
    SUM(order_delivered_customer_date IS NULL) AS delivered_date_null,
    SUM(order_estimated_delivery_date IS NULL) AS estimated_date_null
FROM orders;

SELECT
    COUNT(*) AS total_reviews,

    SUM(review_score IS NULL) AS score_null,
    SUM(review_comment_title IS NULL) AS title_null,
    SUM(review_comment_message IS NULL) AS message_null
FROM reviews;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM customers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM orders;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM products;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids
FROM sellers;

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS cnt
FROM order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS cnt
FROM payments
GROUP BY
    order_id,
    payment_sequential
HAVING COUNT(*) > 1;

SELECT
    review_id,
    COUNT(*) AS cnt
FROM reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

SELECT
    review_id,
    order_id,
    COUNT(*) AS cnt
FROM reviews
GROUP BY
    review_id,
    order_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS duplicate_rows
FROM (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS cnt
    FROM geolocations
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT(*) > 1
) t;

SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_reviews
FROM reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price
FROM order_items;

SELECT *
FROM order_items
WHERE price <= 0;

SELECT
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight,
    AVG(freight_value) AS avg_freight
FROM order_items;

SELECT *
FROM order_items
WHERE freight_value < 0;

SELECT
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment,
    AVG(payment_value) AS avg_payment
FROM payments;

SELECT *
FROM payments
WHERE payment_value < 0;

SELECT
    MIN(review_score) AS min_score,
    MAX(review_score) AS max_score
FROM reviews;

SELECT *
FROM reviews
WHERE review_score NOT BETWEEN 1 AND 5;

SELECT COUNT(*) AS invalid_approval_time
FROM orders
WHERE order_approved_at IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;

SELECT COUNT(*) AS invalid_carrier_time
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date < order_approved_at;

SELECT COUNT(*) AS invalid_delivery_time
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;

SELECT
    order_id,
    product_id,
    price,
    freight_value
FROM order_items
ORDER BY price DESC
LIMIT 20;

SELECT
    order_id,
    product_id,
    price,
    freight_value
FROM order_items
ORDER BY freight_value DESC
LIMIT 20;

