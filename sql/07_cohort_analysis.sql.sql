-- =========================================================
-- 07 Cohort Analysis
-- ---------------------------------------------------------
-- Purpose:
-- Analyze customer repeat-purchase behavior by first
-- purchase cohort and evaluate cohort quality over time.
-- =========================================================

CREATE VIEW vw_customer_cohort AS

SELECT
    customer_unique_id,

    MIN(order_purchase_timestamp) AS first_purchase_time,

    CAST(
        DATE_FORMAT(
            MIN(order_purchase_timestamp),
            '%Y-%m-01'
        ) AS DATE
    ) AS cohort_month

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL

GROUP BY customer_unique_id;


CREATE VIEW vw_customer_month_activity AS

SELECT
    customer_unique_id,

    CAST(
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m-01'
        ) AS DATE
    ) AS activity_month,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS monthly_gmv,

    SUM(item_count) AS items

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL

GROUP BY
    customer_unique_id,
    CAST(
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m-01'
        ) AS DATE
    );


CREATE VIEW vw_customer_cohort_activity AS

SELECT
    a.customer_unique_id,

    c.cohort_month,

    a.activity_month,

    TIMESTAMPDIFF(
        MONTH,
        c.cohort_month,
        a.activity_month
    ) AS cohort_index,

    a.orders,
    a.monthly_gmv,
    a.items

FROM vw_customer_month_activity a

INNER JOIN vw_customer_cohort c
    ON a.customer_unique_id =
       c.customer_unique_id;




CREATE VIEW vw_cohort_size AS

SELECT
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS cohort_size

FROM vw_customer_cohort

GROUP BY cohort_month;


SELECT
    cohort_month,
    cohort_index,

    COUNT(DISTINCT customer_unique_id)
        AS active_customers

FROM vw_customer_cohort_activity

GROUP BY
    cohort_month,
    cohort_index

ORDER BY
    cohort_month,
    cohort_index;




CREATE VIEW vw_cohort_retention AS

WITH cohort_activity AS (

    SELECT
        cohort_month,
        cohort_index,

        COUNT(DISTINCT customer_unique_id)
            AS active_customers

    FROM vw_customer_cohort_activity

    GROUP BY
        cohort_month,
        cohort_index
)

SELECT
    ca.cohort_month,
    ca.cohort_index,

    cs.cohort_size,

    ca.active_customers,

    ROUND(
        ca.active_customers * 100.0
        / NULLIF(cs.cohort_size, 0),
        2
    ) AS retention_rate

FROM cohort_activity ca

INNER JOIN vw_cohort_size cs
    ON ca.cohort_month = cs.cohort_month;




SELECT
    cohort_month,
    MAX(cohort_size) AS cohort_size,

    MAX(
        CASE WHEN cohort_index = 0
             THEN retention_rate END
    ) AS M0,

    MAX(
        CASE WHEN cohort_index = 1
             THEN retention_rate END
    ) AS M1,

    MAX(
        CASE WHEN cohort_index = 2
             THEN retention_rate END
    ) AS M2,

    MAX(
        CASE WHEN cohort_index = 3
             THEN retention_rate END
    ) AS M3,

    MAX(
        CASE WHEN cohort_index = 4
             THEN retention_rate END
    ) AS M4,

    MAX(
        CASE WHEN cohort_index = 5
             THEN retention_rate END
    ) AS M5,

    MAX(
        CASE WHEN cohort_index = 6
             THEN retention_rate END
    ) AS M6,

    MAX(
        CASE WHEN cohort_index = 7
             THEN retention_rate END
    ) AS M7,

    MAX(
        CASE WHEN cohort_index = 8
             THEN retention_rate END
    ) AS M8,

    MAX(
        CASE WHEN cohort_index = 9
             THEN retention_rate END
    ) AS M9,

    MAX(
        CASE WHEN cohort_index = 10
             THEN retention_rate END
    ) AS M10,

    MAX(
        CASE WHEN cohort_index = 11
             THEN retention_rate END
    ) AS M11,

    MAX(
        CASE WHEN cohort_index = 12
             THEN retention_rate END
    ) AS M12

FROM vw_cohort_retention

GROUP BY cohort_month

ORDER BY cohort_month;





SELECT
    cohort_index,

    COUNT(*) AS eligible_cohorts,

    ROUND(
        AVG(retention_rate),
        2
    ) AS avg_retention_rate

FROM vw_cohort_retention

WHERE cohort_index BETWEEN 1 AND 12

GROUP BY cohort_index

ORDER BY cohort_index;




SELECT
    cohort_index,

    SUM(active_customers)
        AS retained_customers,

    SUM(cohort_size)
        AS eligible_customers,

    ROUND(
        SUM(active_customers) * 100.0
        / NULLIF(SUM(cohort_size), 0),
        2
    ) AS weighted_retention_rate

FROM vw_cohort_retention

WHERE cohort_index BETWEEN 1 AND 12

GROUP BY cohort_index

ORDER BY cohort_index;





CREATE VIEW vw_cohort_gmv AS

SELECT
    cohort_month,
    cohort_index,

    COUNT(DISTINCT customer_unique_id)
        AS purchasing_customers,

    ROUND(
        SUM(monthly_gmv),
        2
    ) AS cohort_gmv,

    ROUND(
        SUM(monthly_gmv)
        /
        NULLIF(
            COUNT(DISTINCT customer_unique_id),
            0
        ),
        2
    ) AS gmv_per_active_customer

FROM vw_customer_cohort_activity

GROUP BY
    cohort_month,
    cohort_index;


SELECT
    g.cohort_month,
    g.cohort_index,

    s.cohort_size,

    g.cohort_gmv,

    ROUND(
        g.cohort_gmv
        / NULLIF(s.cohort_size, 0),
        2
    ) AS gmv_per_original_customer

FROM vw_cohort_gmv g

INNER JOIN vw_cohort_size s
    ON g.cohort_month = s.cohort_month

ORDER BY
    g.cohort_month,
    g.cohort_index;



SELECT
    cohort_month,
    MAX(cohort_size) AS cohort_size,

    MAX(
        CASE
            WHEN cohort_index = 1
            THEN retention_rate
        END
    ) AS M1_retention,

    MAX(
        CASE
            WHEN cohort_index = 3
            THEN retention_rate
        END
    ) AS M3_retention,

    MAX(
        CASE
            WHEN cohort_index = 6
            THEN retention_rate
        END
    ) AS M6_retention

FROM vw_cohort_retention

GROUP BY cohort_month

ORDER BY cohort_month;




SELECT
    r.cohort_month,

    MAX(r.cohort_size)
        AS new_customers,

    MAX(
        CASE
            WHEN r.cohort_index = 1
            THEN r.retention_rate
        END
    ) AS M1_retention_rate

FROM vw_cohort_retention r

GROUP BY r.cohort_month

ORDER BY r.cohort_month;



WITH first_orders AS (

    SELECT
        customer_unique_id,
        merchandise_gmv,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY
                order_purchase_timestamp,
                order_id
        ) AS rn

    FROM vw_order_fact

    WHERE order_status = 'delivered'
      AND customer_unique_id IS NOT NULL
)

SELECT
    c.cohort_month,

    COUNT(*) AS new_customers,

    ROUND(
        AVG(f.merchandise_gmv),
        2
    ) AS first_order_aov

FROM vw_customer_cohort c

INNER JOIN first_orders f
    ON c.customer_unique_id =
       f.customer_unique_id

WHERE f.rn = 1

GROUP BY c.cohort_month

ORDER BY c.cohort_month;




CREATE VIEW vw_cohort_quality AS

WITH retention AS (

    SELECT
        cohort_month,

        MAX(cohort_size) AS cohort_size,

        MAX(
            CASE WHEN cohort_index = 1
                 THEN retention_rate END
        ) AS m1_retention_rate,

        MAX(
            CASE WHEN cohort_index = 3
                 THEN retention_rate END
        ) AS m3_retention_rate,

        MAX(
            CASE WHEN cohort_index = 6
                 THEN retention_rate END
        ) AS m6_retention_rate

    FROM vw_cohort_retention

    GROUP BY cohort_month
),

first_orders AS (

    SELECT
        customer_unique_id,
        merchandise_gmv,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY
                order_purchase_timestamp,
                order_id
        ) AS rn

    FROM vw_order_fact

    WHERE order_status = 'delivered'
      AND customer_unique_id IS NOT NULL
),

first_order_value AS (

    SELECT
        c.cohort_month,

        AVG(f.merchandise_gmv)
            AS first_order_aov

    FROM vw_customer_cohort c

    INNER JOIN first_orders f
        ON c.customer_unique_id =
           f.customer_unique_id

    WHERE f.rn = 1

    GROUP BY c.cohort_month
)

SELECT
    r.cohort_month,
    r.cohort_size,

    ROUND(
        f.first_order_aov,
        2
    ) AS first_order_aov,

    r.m1_retention_rate,
    r.m3_retention_rate,
    r.m6_retention_rate

FROM retention r

LEFT JOIN first_order_value f
    ON r.cohort_month = f.cohort_month;