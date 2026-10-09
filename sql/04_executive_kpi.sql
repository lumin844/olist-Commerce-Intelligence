-- =========================================================
-- 04 Executive KPI Framework
-- ---------------------------------------------------------
-- Purpose:
-- Define standardized executive-level KPIs for
-- business performance, customer value, fulfillment
-- and customer experience.
-- =========================================================

-- =========================================================
-- 1. Core Business KPIs
-- =========================================================

SELECT
    COUNT(DISTINCT order_id) AS delivered_orders,

    COUNT(DISTINCT customer_unique_id) AS purchasing_customers,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(gross_order_value),
        2
    ) AS gross_order_value,

    ROUND(
        SUM(freight_value),
        2
    ) AS total_freight,

    ROUND(
        SUM(merchandise_gmv)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS avg_order_value,

    ROUND(
        SUM(item_count)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS avg_items_per_order,

    ROUND(
        SUM(freight_value)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS avg_freight_per_order

FROM vw_order_fact

WHERE order_status = 'delivered';

-- =========================================================
-- 2. Customer Experience KPI
-- =========================================================

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(avg_review_score) AS reviewed_orders,

    ROUND(
        AVG(avg_review_score),
        2
    ) AS avg_review_score

FROM vw_order_fact

WHERE order_status = 'delivered';

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(avg_review_score) AS reviewed_orders,

    ROUND(
        COUNT(avg_review_score) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS review_coverage_rate

FROM vw_order_fact

WHERE order_status = 'delivered';

-- =========================================================
-- 3. Fulfillment KPIs
-- =========================================================

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(delivery_days) AS orders_with_delivery_data,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    SUM(
        CASE
            WHEN is_delayed = 1 THEN 1
            ELSE 0
        END
    ) AS delayed_orders,

    ROUND(
        SUM(
            CASE
                WHEN is_delayed = 1 THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(is_delayed), 0),
        2
    ) AS delay_rate

FROM vw_order_fact

WHERE order_status = 'delivered';

SELECT
    ROUND(
        SUM(
            CASE
                WHEN is_delayed = 0 THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(is_delayed), 0),
        2
    ) AS on_time_delivery_rate

FROM vw_order_fact

WHERE order_status = 'delivered';

-- =========================================================
-- 4. Order Status KPI
-- =========================================================

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered'
            THEN 1 ELSE 0
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN order_status = 'canceled'
            THEN 1 ELSE 0
        END
    ) AS canceled_orders,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'canceled'
                THEN 1 ELSE 0
            END
        ) * 100.0
        / COUNT(*),
        2
    ) AS cancellation_rate

FROM vw_order_fact;

-- =========================================================
-- 5. Customer Retention KPI
-- =========================================================

SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN order_count = 1
            THEN 1 ELSE 0
        END
    ) AS one_time_customers,

    SUM(
        CASE
            WHEN order_count >= 2
            THEN 1 ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        SUM(
            CASE
                WHEN order_count >= 2
                THEN 1 ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate

FROM vw_customer_summary;

SELECT
    CASE
        WHEN order_count = 1
            THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customers,

    ROUND(
        SUM(lifetime_merchandise_value),
        2
    ) AS total_gmv,

    ROUND(
        AVG(lifetime_merchandise_value),
        2
    ) AS avg_customer_value,

    ROUND(
        AVG(order_count),
        2
    ) AS avg_orders_per_customer

FROM vw_customer_summary

GROUP BY
    CASE
        WHEN order_count = 1
            THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END;

SELECT
    ROUND(
        SUM(freight_value),
        2
    ) AS total_freight,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(freight_value) * 100.0
        / NULLIF(SUM(merchandise_gmv), 0),
        2
    ) AS freight_to_gmv_rate

FROM vw_order_fact

WHERE order_status = 'delivered';

SELECT
    ROUND(
        SUM(total_payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        AVG(total_payment_value),
        2
    ) AS avg_payment_value,

    ROUND(
        AVG(max_installments),
        2
    ) AS avg_max_installments

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND total_payment_value IS NOT NULL;



CREATE VIEW vw_executive_kpi AS

SELECT

    -- ============================
    -- Business Performance
    -- ============================

    COUNT(DISTINCT order_id)
        AS delivered_orders,

    COUNT(DISTINCT customer_unique_id)
        AS purchasing_customers,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(gross_order_value),
        2
    ) AS gross_order_value,

    ROUND(
        SUM(merchandise_gmv)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS avg_order_value,

    ROUND(
        SUM(item_count)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS avg_items_per_order,

    -- ============================
    -- Freight
    -- ============================

    ROUND(
        SUM(freight_value),
        2
    ) AS total_freight,

    ROUND(
        SUM(freight_value)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS avg_freight_per_order,

    ROUND(
        SUM(freight_value) * 100.0
        / NULLIF(SUM(merchandise_gmv), 0),
        2
    ) AS freight_to_gmv_rate,

    -- ============================
    -- Customer Experience
    -- ============================

    ROUND(
        AVG(avg_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        COUNT(avg_review_score) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS review_coverage_rate,

    -- ============================
    -- Fulfillment
    -- ============================

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        SUM(
            CASE
                WHEN is_delayed = 1
                THEN 1 ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(is_delayed), 0),
        2
    ) AS delay_rate

FROM vw_order_fact

WHERE order_status = 'delivered';