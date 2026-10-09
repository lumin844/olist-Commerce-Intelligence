-- =========================================================
-- 06 Customer Intelligence
-- ---------------------------------------------------------
-- Purpose:
-- Analyze customer purchasing behavior, repeat purchase,
-- customer value contribution and purchase frequency.
-- =========================================================

CREATE VIEW vw_customer_intelligence AS

SELECT
    customer_unique_id,

    MIN(order_purchase_timestamp) AS first_purchase_time,
    MAX(order_purchase_timestamp) AS last_purchase_time,

    DATE(MIN(order_purchase_timestamp)) AS first_purchase_date,
    DATE(MAX(order_purchase_timestamp)) AS last_purchase_date,

    COUNT(DISTINCT order_id) AS order_count,

    COUNT(DISTINCT purchase_year_month) AS active_purchase_months,

    SUM(item_count) AS total_items,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS lifetime_merchandise_value,

    ROUND(
        SUM(freight_value),
        2
    ) AS lifetime_freight_value,

    ROUND(
        SUM(gross_order_value),
        2
    ) AS lifetime_gross_order_value,

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
        AVG(avg_review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    DATEDIFF(
        MAX(order_purchase_timestamp),
        MIN(order_purchase_timestamp)
    ) AS customer_lifetime_days,

    CASE
        WHEN COUNT(DISTINCT order_id) >= 2
        THEN 'Repeat Customer'
        ELSE 'One-time Customer'
    END AS customer_type

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL

GROUP BY customer_unique_id;

SELECT
    order_count,
    COUNT(*) AS customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM vw_customer_intelligence

GROUP BY order_count

ORDER BY order_count;

SELECT
    CASE
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count = 2 THEN '2 orders'
        WHEN order_count = 3 THEN '3 orders'
        WHEN order_count = 4 THEN '4 orders'
        ELSE '5+ orders'
    END AS purchase_frequency,

    COUNT(*) AS customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM vw_customer_intelligence

GROUP BY
    CASE
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count = 2 THEN '2 orders'
        WHEN order_count = 3 THEN '3 orders'
        WHEN order_count = 4 THEN '4 orders'
        ELSE '5+ orders'
    END

ORDER BY MIN(order_count);

SELECT
    customer_type,

    COUNT(*) AS customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM vw_customer_intelligence

GROUP BY customer_type;


SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN order_count >= 2
            THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        SUM(
            CASE
                WHEN order_count >= 2
                THEN 1
                ELSE 0
            END
        ) * 100.0
        / COUNT(*),
        2
    ) AS repeat_customer_rate

FROM vw_customer_intelligence;



SELECT
    customer_type,

    COUNT(*) AS customers,

    SUM(order_count) AS orders,

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
    ) AS avg_orders_per_customer,

    ROUND(
        AVG(avg_order_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(total_items),
        2
    ) AS avg_items_per_customer

FROM vw_customer_intelligence

GROUP BY customer_type;




SELECT
    customer_type,

    ROUND(
        SUM(lifetime_merchandise_value),
        2
    ) AS gmv,

    ROUND(
        SUM(lifetime_merchandise_value)
        * 100.0
        /
        SUM(
            SUM(lifetime_merchandise_value)
        ) OVER (),
        2
    ) AS gmv_share_pct

FROM vw_customer_intelligence

GROUP BY customer_type;



WITH customer_value AS (

    SELECT
        customer_type,

        AVG(
            lifetime_merchandise_value
        ) AS avg_customer_value

    FROM vw_customer_intelligence

    GROUP BY customer_type
)

SELECT
    ROUND(
        MAX(
            CASE
                WHEN customer_type = 'Repeat Customer'
                THEN avg_customer_value
            END
        )
        /
        NULLIF(
            MAX(
                CASE
                    WHEN customer_type = 'One-time Customer'
                    THEN avg_customer_value
                END
            ),
            0
        ),
        2
    ) AS repeat_customer_value_multiple

FROM customer_value;


SELECT
    ROUND(MIN(lifetime_merchandise_value), 2)
        AS min_customer_value,

    ROUND(AVG(lifetime_merchandise_value), 2)
        AS avg_customer_value,

    ROUND(MAX(lifetime_merchandise_value), 2)
        AS max_customer_value

FROM vw_customer_intelligence;


SELECT
    CASE
        WHEN lifetime_merchandise_value < 50
            THEN '< 50'

        WHEN lifetime_merchandise_value < 100
            THEN '50-99'

        WHEN lifetime_merchandise_value < 200
            THEN '100-199'

        WHEN lifetime_merchandise_value < 500
            THEN '200-499'

        WHEN lifetime_merchandise_value < 1000
            THEN '500-999'

        ELSE '1000+'
    END AS value_band,

    COUNT(*) AS customers,

    ROUND(
        SUM(lifetime_merchandise_value),
        2
    ) AS gmv,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM vw_customer_intelligence

GROUP BY
    CASE
        WHEN lifetime_merchandise_value < 50
            THEN '< 50'
        WHEN lifetime_merchandise_value < 100
            THEN '50-99'
        WHEN lifetime_merchandise_value < 200
            THEN '100-199'
        WHEN lifetime_merchandise_value < 500
            THEN '200-499'
        WHEN lifetime_merchandise_value < 1000
            THEN '500-999'
        ELSE '1000+'
    END;


WITH customer_rank AS (

    SELECT
        customer_unique_id,
        lifetime_merchandise_value,

        ROW_NUMBER() OVER (
            ORDER BY lifetime_merchandise_value DESC
        ) AS customer_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(lifetime_merchandise_value)
        OVER () AS total_gmv

    FROM vw_customer_intelligence
)

SELECT
    customer_rank,
    customer_unique_id,
    lifetime_merchandise_value,

    ROUND(
        customer_rank * 100.0
        / total_customers,
        2
    ) AS customer_percentile,

    ROUND(
        SUM(lifetime_merchandise_value)
        OVER (
            ORDER BY customer_rank
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        * 100.0
        / total_gmv,
        2
    ) AS cumulative_gmv_share

FROM customer_rank

ORDER BY customer_rank;



WITH ranked AS (

    SELECT
        customer_unique_id,
        lifetime_merchandise_value,

        NTILE(10) OVER (
            ORDER BY lifetime_merchandise_value DESC
        ) AS value_decile

    FROM vw_customer_intelligence
)

SELECT
    value_decile,

    COUNT(*) AS customers,

    ROUND(
        SUM(lifetime_merchandise_value),
        2
    ) AS gmv,

    ROUND(
        SUM(lifetime_merchandise_value)
        * 100.0
        /
        SUM(
            SUM(lifetime_merchandise_value)
        ) OVER (),
        2
    ) AS gmv_share_pct

FROM ranked

GROUP BY value_decile

ORDER BY value_decile;



CREATE VIEW vw_customer_order_sequence AS

SELECT
    customer_unique_id,
    order_id,
    order_purchase_timestamp,
    purchase_year_month,
    merchandise_gmv,

    ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchase_timestamp, order_id
    ) AS purchase_sequence,

    LAG(order_purchase_timestamp) OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchase_timestamp, order_id
    ) AS previous_purchase_time

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL;


SELECT
    customer_unique_id,
    order_id,
    purchase_sequence,

    previous_purchase_time,
    order_purchase_timestamp,

    DATEDIFF(
        order_purchase_timestamp,
        previous_purchase_time
    ) AS days_since_previous_purchase

FROM vw_customer_order_sequence

WHERE purchase_sequence >= 2

ORDER BY
    customer_unique_id,
    purchase_sequence;



WITH repeat_orders AS (

    SELECT
        customer_unique_id,

        DATEDIFF(
            order_purchase_timestamp,
            previous_purchase_time
        ) AS days_since_previous_purchase

    FROM vw_customer_order_sequence

    WHERE purchase_sequence >= 2
      AND previous_purchase_time IS NOT NULL
)

SELECT
    COUNT(*) AS repeat_purchase_events,

    ROUND(
        AVG(days_since_previous_purchase),
        2
    ) AS avg_days_between_purchases,

    MIN(days_since_previous_purchase)
        AS min_days_between_purchases,

    MAX(days_since_previous_purchase)
        AS max_days_between_purchases

FROM repeat_orders;


SELECT
    customer_unique_id,

    MIN(
        CASE
            WHEN purchase_sequence = 1
            THEN order_purchase_timestamp
        END
    ) AS first_purchase_time,

    MIN(
        CASE
            WHEN purchase_sequence = 2
            THEN order_purchase_timestamp
        END
    ) AS second_purchase_time,

    DATEDIFF(
        MIN(
            CASE
                WHEN purchase_sequence = 2
                THEN order_purchase_timestamp
            END
        ),
        MIN(
            CASE
                WHEN purchase_sequence = 1
                THEN order_purchase_timestamp
            END
        )
    ) AS days_to_second_purchase

FROM vw_customer_order_sequence

GROUP BY customer_unique_id

HAVING COUNT(*) >= 2;



WITH second_purchase AS (

    SELECT
        customer_unique_id,

        DATEDIFF(
            MIN(
                CASE
                    WHEN purchase_sequence = 2
                    THEN order_purchase_timestamp
                END
            ),
            MIN(
                CASE
                    WHEN purchase_sequence = 1
                    THEN order_purchase_timestamp
                END
            )
        ) AS days_to_second_purchase

    FROM vw_customer_order_sequence

    GROUP BY customer_unique_id

    HAVING COUNT(*) >= 2
)

SELECT
    CASE
        WHEN days_to_second_purchase <= 7
            THEN '0-7 days'

        WHEN days_to_second_purchase <= 30
            THEN '8-30 days'

        WHEN days_to_second_purchase <= 60
            THEN '31-60 days'

        WHEN days_to_second_purchase <= 90
            THEN '61-90 days'

        WHEN days_to_second_purchase <= 180
            THEN '91-180 days'

        ELSE '180+ days'
    END AS repurchase_interval,

    COUNT(*) AS customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM second_purchase

GROUP BY
    CASE
        WHEN days_to_second_purchase <= 7
            THEN '0-7 days'
        WHEN days_to_second_purchase <= 30
            THEN '8-30 days'
        WHEN days_to_second_purchase <= 60
            THEN '31-60 days'
        WHEN days_to_second_purchase <= 90
            THEN '61-90 days'
        WHEN days_to_second_purchase <= 180
            THEN '91-180 days'
        ELSE '180+ days'
    END

ORDER BY MIN(days_to_second_purchase);


SELECT
    CASE
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count = 2 THEN '2 orders'
        WHEN order_count = 3 THEN '3 orders'
        WHEN order_count = 4 THEN '4 orders'
        ELSE '5+ orders'
    END AS purchase_frequency,

    COUNT(*) AS customers,

    ROUND(
        AVG(lifetime_merchandise_value),
        2
    ) AS avg_customer_value,

    ROUND(
        AVG(avg_order_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(total_items),
        2
    ) AS avg_items_per_customer

FROM vw_customer_intelligence

GROUP BY
    CASE
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count = 2 THEN '2 orders'
        WHEN order_count = 3 THEN '3 orders'
        WHEN order_count = 4 THEN '4 orders'
        ELSE '5+ orders'
    END

ORDER BY MIN(order_count);




CREATE VIEW vw_customer_dashboard AS

SELECT
    customer_unique_id,

    first_purchase_date,
    last_purchase_date,

    order_count,
    active_purchase_months,
    total_items,

    lifetime_merchandise_value,
    lifetime_freight_value,
    lifetime_gross_order_value,

    avg_order_value,
    avg_items_per_order,

    avg_review_score,
    avg_delivery_days,

    customer_lifetime_days,

    customer_type,

    CASE
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count = 2 THEN '2 orders'
        WHEN order_count = 3 THEN '3 orders'
        WHEN order_count = 4 THEN '4 orders'
        ELSE '5+ orders'
    END AS purchase_frequency_band

FROM vw_customer_intelligence;