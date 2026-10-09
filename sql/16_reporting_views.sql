-- =========================================================
-- 16 Reporting Layer
-- ---------------------------------------------------------
-- Purpose:
-- Build a compact reporting layer for Power BI,
-- preserve clear table grain, reduce model complexity,
-- and separate SQL business logic from DAX measures.
-- =========================================================
CREATE VIEW rpt_fact_order AS

SELECT
    f.order_id,
    f.customer_unique_id,

    DATE(f.order_purchase_timestamp)
        AS purchase_date,

    CAST(
        DATE_FORMAT(
            f.order_purchase_timestamp,
            '%Y%m%d'
        ) AS UNSIGNED
    ) AS purchase_date_key,

    f.purchase_year_month,

    f.order_status,
    f.is_delivered,
    f.is_canceled,

    f.customer_city,
    f.customer_state,

    f.item_count,
    f.distinct_product_count,
    f.distinct_seller_count,

    f.merchandise_gmv,
    f.freight_value,
    f.gross_order_value,

    f.total_payment_value,
    f.payment_method_count,
    f.payment_methods,

    ppm.primary_payment_method,

    r.review_score,

    CASE
        WHEN r.review_score >= 4 THEN 'Positive'
        WHEN r.review_score = 3 THEN 'Neutral'
        WHEN r.review_score <= 2 THEN 'Negative'
        ELSE 'No Review'
    END AS satisfaction_group,

    f.delivery_days,
    f.delay_days,
    f.is_delayed,

    CASE
        WHEN f.order_delivered_customer_date IS NULL
        THEN 'Unknown'

        WHEN DATE(f.order_delivered_customer_date)
             < DATE(f.order_estimated_delivery_date)
        THEN 'Early'

        WHEN DATE(f.order_delivered_customer_date)
             = DATE(f.order_estimated_delivery_date)
        THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status

FROM vw_order_fact f

LEFT JOIN vw_order_review_latest r
    ON f.order_id = r.order_id

LEFT JOIN vw_primary_payment_method ppm
    ON f.order_id = ppm.order_id;




CREATE VIEW rpt_fact_order_item AS

SELECT
    i.order_id,
    i.order_item_id,

    i.customer_unique_id,

    CAST(
        DATE_FORMAT(
            i.order_purchase_timestamp,
            '%Y%m%d'
        ) AS UNSIGNED
    ) AS purchase_date_key,

    DATE(i.order_purchase_timestamp)
        AS purchase_date,

    i.purchase_year_month,

    i.product_id,
    i.product_category,

    i.seller_id,
    s.seller_state,

    i.customer_state,

    i.price,
    i.freight_value,
    i.item_gross_value,

    r.review_score,

    i.delivery_days,
    i.delay_days,
    i.is_delayed,

    i.product_weight_g,
    i.product_length_cm,
    i.product_height_cm,
    i.product_width_cm

FROM vw_order_item_enriched i

LEFT JOIN sellers s
    ON i.seller_id = s.seller_id

LEFT JOIN vw_order_review_latest r
    ON i.order_id = r.order_id

WHERE i.order_status = 'delivered';




CREATE VIEW rpt_dim_customer AS

SELECT
    c.customer_unique_id,

    c.first_purchase_date,
    c.last_purchase_date,

    c.order_count,
    c.active_purchase_months,
    c.total_items,

    c.lifetime_merchandise_value,
    c.avg_order_value,

    c.customer_lifetime_days,
    c.customer_type,

    r.recency_days,
    r.frequency,
    r.monetary_value,

    r.r_score,
    r.f_score,
    r.m_score,

    r.rfm_code,
    r.rfm_total_score,

    r.customer_segment,
    r.value_tier

FROM vw_customer_intelligence c

LEFT JOIN vw_rfm_segments r
    ON c.customer_unique_id =
       r.customer_unique_id;




CREATE VIEW rpt_dim_category AS

SELECT DISTINCT
    product_category
FROM vw_order_item_enriched;



CREATE VIEW rpt_dim_seller AS

SELECT
    seller_id,
    seller_city,
    seller_state,
    seller_zip_code_prefix

FROM sellers;




CREATE TABLE dim_date (

    date_key INT PRIMARY KEY,

    full_date DATE NOT NULL,

    year_num SMALLINT NOT NULL,

    quarter_num TINYINT NOT NULL,

    quarter_name VARCHAR(5) NOT NULL,

    month_num TINYINT NOT NULL,

    month_name VARCHAR(15) NOT NULL,

    year_month2 VARCHAR(7) NOT NULL,

    year_month_sort INT NOT NULL,

    month_start DATE NOT NULL,

    day_of_month TINYINT NOT NULL,

    day_of_week TINYINT NOT NULL,

    day_name VARCHAR(15) NOT NULL

);


WITH RECURSIVE date_range AS (
    SELECT
        MIN(DATE(order_purchase_timestamp)) AS dt,
        MAX(DATE(order_purchase_timestamp)) AS max_dt
    FROM orders

    UNION ALL

    SELECT
        DATE_ADD(dt, INTERVAL 1 DAY),
        max_dt
    FROM date_range
    WHERE dt < max_dt
)

SELECT *
FROM date_range;


WITH RECURSIVE date_range AS (
    SELECT
        MIN(DATE(order_purchase_timestamp)) AS dt,
        MAX(DATE(order_purchase_timestamp)) AS max_dt
    FROM orders

    UNION ALL

    SELECT
        DATE_ADD(dt, INTERVAL 1 DAY),
        max_dt
    FROM date_range
    WHERE dt < max_dt
)

SELECT
    dt,
    YEAR(dt) AS year_num,
    MONTH(dt) AS month_num,
    DAY(dt) AS day_num
FROM date_range;


INSERT INTO dim_date (
    date_key,
    full_date,
    year_num,
    quarter_num,
    quarter_name,
    month_num,
    month_name,
    year_month2,
    year_month_sort,
    month_start,
    day_of_month,
    day_of_week,
    day_name
)

WITH RECURSIVE date_range AS (
    SELECT
        MIN(DATE(order_purchase_timestamp)) AS dt,
        MAX(DATE(order_purchase_timestamp)) AS max_dt
    FROM orders

    UNION ALL

    SELECT
        DATE_ADD(dt, INTERVAL 1 DAY),
        max_dt
    FROM date_range
    WHERE dt < max_dt
)

SELECT
    YEAR(dt) * 10000
        + MONTH(dt) * 100
        + DAY(dt) AS date_key,

    dt AS full_date,

    YEAR(dt) AS year_num,

    QUARTER(dt) AS quarter_num,

    CONCAT(
        'Q',
        QUARTER(dt)
    ) AS quarter_name,

    MONTH(dt) AS month_num,

    DATE_FORMAT(dt, '%M') AS month_name,

    DATE_FORMAT(dt, '%Y-%m') AS year_month2,

    YEAR(dt) * 100
        + MONTH(dt) AS year_month_sort,

    DATE_SUB(
        dt,
        INTERVAL (DAY(dt) - 1) DAY
    ) AS month_start,

    DAY(dt) AS day_of_month,

    DAYOFWEEK(dt) AS day_of_week,

    DAYNAME(dt) AS day_name

FROM date_range;


CREATE VIEW rpt_fact_cohort AS

SELECT
    cohort_month,

    DATE_FORMAT(
        cohort_month,
        '%Y-%m'
    ) AS cohort_label,

    cohort_index,

    cohort_size,
    active_customers,
    retention_rate

FROM vw_cohort_retention;




CREATE VIEW rpt_fact_seller_performance AS

SELECT
    seller_id,
    seller_state,

    orders,
    customers,
    merchandise_gmv,

    avg_review_score,
    low_rating_rate,

    avg_delivery_days,
    delay_rate,

    late_dispatch_rate,
    avg_hours_vs_deadline

FROM vw_seller_diagnostic;






CREATE VIEW rpt_fact_distance AS

SELECT
    d.order_id,
    d.seller_id,
    d.customer_unique_id,

    DATE(f.order_purchase_timestamp)
        AS purchase_date,

    CAST(
        DATE_FORMAT(
            f.order_purchase_timestamp,
            '%Y%m%d'
        ) AS UNSIGNED
    ) AS purchase_date_key,

    d.seller_state,
    d.customer_state,

    d.straight_line_distance_km,
    d.distance_band,

    d.merchandise_gmv,
    d.freight_value,

    d.delivery_days,
    d.delay_days,
    d.is_delayed,

    d.review_score,

    d.geographic_relation

FROM vw_distance_dashboard d

INNER JOIN vw_order_fact f
    ON d.order_id = f.order_id;




CREATE VIEW rpt_dim_state AS

SELECT DISTINCT
    customer_state AS state_code,
    'Brazil' AS country
FROM customers
WHERE customer_state IS NOT NULL

UNION

SELECT DISTINCT
    seller_state AS state_code,
    'Brazil' AS country
FROM sellers
WHERE seller_state IS NOT NULL;


CREATE VIEW rpt_fact_state_performance AS

SELECT
    state_code,

    customer_orders,
    customers,

    customer_demand_gmv,
    demand_gmv_share_pct,

    aov,

    freight_per_order,
    freight_to_gmv_pct,

    avg_delivery_days,
    delay_rate,

    avg_review_score,
    low_rating_rate,

    sellers,
    seller_origin_gmv,
    supply_gmv_share_pct,

    supply_demand_share_gap_pp,

    country

FROM vw_state_market_dashboard;

select * from rpt_fact_distance limit 10;



CREATE VIEW rpt_fact_category_performance AS

SELECT
    product_category,

    orders,
    customers,

    merchandise_gmv,
    freight_value,
    freight_to_gmv_pct,

    abc_class,
    gmv_share_pct,
    cumulative_gmv_share_pct,

    avg_review_score,
    low_rating_rate,
    delay_rate,

    reviewed_orders

FROM vw_category_diagnostic;


