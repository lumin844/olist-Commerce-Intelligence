-- =========================================================
-- Olist Commerce Intelligence 360
-- 05 Growth Intelligence
-- ---------------------------------------------------------
-- Purpose:
-- Analyze business growth from GMV, orders, customers,
-- AOV and customer structure, and identify growth drivers
-- and turning points.
-- =========================================================

CREATE VIEW vw_monthly_performance AS

SELECT
    purchase_year_month AS month,

    COUNT(DISTINCT order_id) AS orders,

    COUNT(DISTINCT customer_unique_id) AS customers,

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
    ) AS freight_value,

    SUM(item_count) AS items_sold,

    ROUND(
        SUM(merchandise_gmv)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS aov,

    ROUND(
        SUM(item_count)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS items_per_order,

    ROUND(
        SUM(freight_value)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS freight_per_order

FROM vw_order_fact

WHERE order_status = 'delivered'

GROUP BY purchase_year_month;

WITH monthly AS (
    SELECT
        month,
        merchandise_gmv
    FROM vw_monthly_performance
)

SELECT
    month,
    merchandise_gmv,

    LAG(merchandise_gmv) OVER (
        ORDER BY month
    ) AS previous_month_gmv,

    ROUND(
        (
            merchandise_gmv
            -
            LAG(merchandise_gmv) OVER (
                ORDER BY month
            )
        )
        * 100.0
        /
        NULLIF(
            LAG(merchandise_gmv) OVER (
                ORDER BY month
            ),
            0
        ),
        2
    ) AS gmv_mom_growth_pct

FROM monthly

ORDER BY month;

WITH monthly AS (
    SELECT
        month,
        orders
    FROM vw_monthly_performance
)

SELECT
    month,
    orders,

    LAG(orders) OVER (
        ORDER BY month
    ) AS previous_month_orders,

    ROUND(
        (
            orders -
            LAG(orders) OVER (ORDER BY month)
        )
        * 100.0
        /
        NULLIF(
            LAG(orders) OVER (ORDER BY month),
            0
        ),
        2
    ) AS order_mom_growth_pct

FROM monthly

ORDER BY month;

WITH monthly AS (
    SELECT
        month,
        customers
    FROM vw_monthly_performance
)

SELECT
    month,
    customers,

    LAG(customers) OVER (
        ORDER BY month
    ) AS previous_month_customers,

    ROUND(
        (
            customers -
            LAG(customers) OVER (ORDER BY month)
        )
        * 100.0
        /
        NULLIF(
            LAG(customers) OVER (ORDER BY month),
            0
        ),
        2
    ) AS customer_mom_growth_pct

FROM monthly

ORDER BY month;

WITH monthly AS (
    SELECT
        month,
        aov
    FROM vw_monthly_performance
)

SELECT
    month,
    aov,

    LAG(aov) OVER (
        ORDER BY month
    ) AS previous_month_aov,

    ROUND(
        (
            aov -
            LAG(aov) OVER (ORDER BY month)
        )
        * 100.0
        /
        NULLIF(
            LAG(aov) OVER (ORDER BY month),
            0
        ),
        2
    ) AS aov_mom_growth_pct

FROM monthly

ORDER BY month;

WITH growth AS (

    SELECT
        month,
        merchandise_gmv,
        orders,
        customers,
        aov,

        LAG(merchandise_gmv)
        OVER (ORDER BY month) AS prev_gmv,

        LAG(orders)
        OVER (ORDER BY month) AS prev_orders,

        LAG(customers)
        OVER (ORDER BY month) AS prev_customers,

        LAG(aov)
        OVER (ORDER BY month) AS prev_aov

    FROM vw_monthly_performance
)

SELECT
    month,

    merchandise_gmv,
    orders,
    customers,
    aov,

    ROUND(
        (merchandise_gmv - prev_gmv)
        * 100.0 / NULLIF(prev_gmv, 0),
        2
    ) AS gmv_growth_pct,

    ROUND(
        (orders - prev_orders)
        * 100.0 / NULLIF(prev_orders, 0),
        2
    ) AS order_growth_pct,

    ROUND(
        (customers - prev_customers)
        * 100.0 / NULLIF(prev_customers, 0),
        2
    ) AS customer_growth_pct,

    ROUND(
        (aov - prev_aov)
        * 100.0 / NULLIF(prev_aov, 0),
        2
    ) AS aov_growth_pct

FROM growth

ORDER BY month;

CREATE VIEW vw_monthly_growth AS

WITH growth AS (

    SELECT
        month,
        merchandise_gmv,
        gross_order_value,
        orders,
        customers,
        aov,
        items_sold,
        items_per_order,

        LAG(merchandise_gmv)
        OVER (ORDER BY month) AS prev_gmv,

        LAG(orders)
        OVER (ORDER BY month) AS prev_orders,

        LAG(customers)
        OVER (ORDER BY month) AS prev_customers,

        LAG(aov)
        OVER (ORDER BY month) AS prev_aov

    FROM vw_monthly_performance
)

SELECT
    month,

    merchandise_gmv,
    gross_order_value,
    orders,
    customers,
    aov,
    items_sold,
    items_per_order,

    ROUND(
        (merchandise_gmv - prev_gmv)
        * 100.0 / NULLIF(prev_gmv, 0),
        2
    ) AS gmv_growth_pct,

    ROUND(
        (orders - prev_orders)
        * 100.0 / NULLIF(prev_orders, 0),
        2
    ) AS order_growth_pct,

    ROUND(
        (customers - prev_customers)
        * 100.0 / NULLIF(prev_customers, 0),
        2
    ) AS customer_growth_pct,

    ROUND(
        (aov - prev_aov)
        * 100.0 / NULLIF(prev_aov, 0),
        2
    ) AS aov_growth_pct

FROM growth;

SELECT
    month,

    gmv_growth_pct,
    order_growth_pct,
    aov_growth_pct,

    CASE

        WHEN gmv_growth_pct IS NULL
        THEN 'N/A'

        WHEN gmv_growth_pct > 0
             AND order_growth_pct > 0
             AND ABS(order_growth_pct) > ABS(aov_growth_pct)
        THEN 'Order-driven Growth'

        WHEN gmv_growth_pct > 0
             AND aov_growth_pct > 0
             AND ABS(aov_growth_pct) > ABS(order_growth_pct)
        THEN 'AOV-driven Growth'

        WHEN gmv_growth_pct > 0
             AND order_growth_pct > 0
             AND aov_growth_pct > 0
        THEN 'Balanced Growth'

        WHEN gmv_growth_pct < 0
        THEN 'Contraction'

        ELSE 'Mixed'

    END AS growth_pattern

FROM vw_monthly_growth

ORDER BY month;



CREATE VIEW vw_customer_first_purchase AS

SELECT
    customer_unique_id,

    MIN(
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        )
    ) AS first_purchase_month

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL

GROUP BY customer_unique_id;


CREATE VIEW vw_order_customer_type AS

SELECT
    f.*,

    CASE
        WHEN f.purchase_year_month =
             c.first_purchase_month
        THEN 'New Customer'

        ELSE 'Returning Customer'
    END AS customer_type

FROM vw_order_fact f

LEFT JOIN vw_customer_first_purchase c
    ON f.customer_unique_id =
       c.customer_unique_id

WHERE f.order_status = 'delivered';

SELECT
    purchase_year_month AS month,

    COUNT(
        DISTINCT CASE
            WHEN customer_type = 'New Customer'
            THEN customer_unique_id
        END
    ) AS new_customers,

    COUNT(
        DISTINCT CASE
            WHEN customer_type = 'Returning Customer'
            THEN customer_unique_id
        END
    ) AS returning_customers

FROM vw_order_customer_type

GROUP BY purchase_year_month

ORDER BY month;

SELECT
    purchase_year_month AS month,

    ROUND(
        SUM(
            CASE
                WHEN customer_type = 'New Customer'
                THEN merchandise_gmv
                ELSE 0
            END
        ),
        2
    ) AS new_customer_gmv,

    ROUND(
        SUM(
            CASE
                WHEN customer_type = 'Returning Customer'
                THEN merchandise_gmv
                ELSE 0
            END
        ),
        2
    ) AS returning_customer_gmv,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS total_gmv

FROM vw_order_customer_type

GROUP BY purchase_year_month

ORDER BY month;

WITH monthly_customer_gmv AS (

    SELECT
        purchase_year_month AS month,

        SUM(
            CASE
                WHEN customer_type = 'New Customer'
                THEN merchandise_gmv
                ELSE 0
            END
        ) AS new_customer_gmv,

        SUM(
            CASE
                WHEN customer_type = 'Returning Customer'
                THEN merchandise_gmv
                ELSE 0
            END
        ) AS returning_customer_gmv,

        SUM(merchandise_gmv) AS total_gmv

    FROM vw_order_customer_type

    GROUP BY purchase_year_month
)

SELECT
    month,

    ROUND(new_customer_gmv, 2)
        AS new_customer_gmv,

    ROUND(returning_customer_gmv, 2)
        AS returning_customer_gmv,

    ROUND(
        new_customer_gmv * 100.0
        / NULLIF(total_gmv, 0),
        2
    ) AS new_customer_gmv_share,

    ROUND(
        returning_customer_gmv * 100.0
        / NULLIF(total_gmv, 0),
        2
    ) AS returning_customer_gmv_share

FROM monthly_customer_gmv

ORDER BY month;

SELECT
    purchase_year_month AS month,
    customer_type,

    COUNT(DISTINCT order_id) AS orders,

    COUNT(DISTINCT customer_unique_id)
        AS customers,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS gmv,

    ROUND(
        SUM(merchandise_gmv)
        /
        NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS aov

FROM vw_order_customer_type

GROUP BY
    purchase_year_month,
    customer_type

ORDER BY
    month,
    customer_type;


CREATE VIEW vw_growth_dashboard AS

WITH customer_metrics AS (

    SELECT
        purchase_year_month AS month,

        COUNT(
            DISTINCT CASE
                WHEN customer_type = 'New Customer'
                THEN customer_unique_id
            END
        ) AS new_customers,

        COUNT(
            DISTINCT CASE
                WHEN customer_type = 'Returning Customer'
                THEN customer_unique_id
            END
        ) AS returning_customers,

        SUM(
            CASE
                WHEN customer_type = 'New Customer'
                THEN merchandise_gmv
                ELSE 0
            END
        ) AS new_customer_gmv,

        SUM(
            CASE
                WHEN customer_type = 'Returning Customer'
                THEN merchandise_gmv
                ELSE 0
            END
        ) AS returning_customer_gmv

    FROM vw_order_customer_type

    GROUP BY purchase_year_month
)

SELECT
    g.month,

    g.merchandise_gmv,
    g.orders,
    g.customers,
    g.aov,

    g.gmv_growth_pct,
    g.order_growth_pct,
    g.customer_growth_pct,
    g.aov_growth_pct,

    c.new_customers,
    c.returning_customers,

    ROUND(c.new_customer_gmv, 2)
        AS new_customer_gmv,

    ROUND(c.returning_customer_gmv, 2)
        AS returning_customer_gmv,

    ROUND(
        c.new_customer_gmv * 100.0
        /
        NULLIF(g.merchandise_gmv, 0),
        2
    ) AS new_customer_gmv_share,

    ROUND(
        c.returning_customer_gmv * 100.0
        /
        NULLIF(g.merchandise_gmv, 0),
        2
    ) AS returning_customer_gmv_share

FROM vw_monthly_growth g

LEFT JOIN customer_metrics c
    ON g.month = c.month;