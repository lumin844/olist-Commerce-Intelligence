-- 1. 原始表数据规模
SHOW TABLES;
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers UNION ALL

SELECT 'orders', COUNT(*) FROM orders UNION ALL

SELECT 'order_items', COUNT(*) FROM order_items UNION ALL

SELECT 'order_payments', COUNT(*) FROM payments UNION ALL

SELECT 'order_reviews', COUNT(*) FROM reviews UNION ALL

SELECT 'products', COUNT(*) FROM products UNION ALL

SELECT 'sellers', COUNT(*) FROM sellers UNION ALL

SELECT 'geolocation', COUNT(*) FROM geolocations UNION ALL

SELECT 'category_translation', COUNT(*) FROM category_translation;

-- 2. 数据粒度检查
SELECT
    COUNT(*) AS total_rows,COUNT(DISTINCT customer_id) AS customer_id_count,COUNT(DISTINCT customer_unique_id) AS unique_customer_count
FROM customers;

SELECT
    COUNT(*) AS total_rows,COUNT(DISTINCT order_id) AS unique_orders,COUNT(DISTINCT customer_id) AS customer_ids
FROM orders;

SELECT
    COUNT(*) AS total_rows,COUNT(DISTINCT order_id) AS orders,COUNT(DISTINCT product_id) AS products,COUNT(DISTINCT seller_id) AS sellers
FROM order_items;

SELECT
    COUNT(*) AS payment_records,COUNT(DISTINCT order_id) AS orders_with_payment
FROM payments;

-- 3. 时间范围
SELECT
    MIN(order_purchase_timestamp) AS first_order_time,MAX(order_purchase_timestamp) AS last_order_time,
    DATEDIFF(
        MAX(order_purchase_timestamp),MIN(order_purchase_timestamp)
    ) AS total_days
FROM orders;

-- 4. 业务分布
SELECT
    order_status,COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM orders
GROUP BY order_status ORDER BY order_count DESC;

SELECT
    payment_type,COUNT(*) AS payment_count,
    ROUND(SUM(payment_value), 2) AS payment_value,ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM payments
GROUP BY payment_type ORDER BY payment_count DESC;

SELECT
    review_score,COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM reviews
GROUP BY review_score
ORDER BY review_score;

SELECT
    (SELECT COUNT(DISTINCT customer_unique_id)
     FROM customers) AS customers,

    (SELECT COUNT(DISTINCT product_id)
     FROM products) AS products,

    (SELECT COUNT(DISTINCT seller_id)
     FROM sellers) AS sellers,

    (SELECT COUNT(DISTINCT product_category_name)
     FROM products) AS categories;

SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS customers
FROM customers
GROUP BY customer_state
ORDER BY customers DESC;

SELECT
    seller_state,
    COUNT(*) AS sellers
FROM sellers
GROUP BY seller_state
ORDER BY sellers DESC;

SELECT
    ct.product_category_name_english AS category,
    COUNT(DISTINCT p.product_id) AS product_count
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY product_count DESC;

