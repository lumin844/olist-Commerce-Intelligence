-- =========================================================
-- 09 Product Portfolio Analysis
-- ---------------------------------------------------------
-- Purpose:
-- Evaluate category revenue contribution, product structure,
-- customer reach, freight burden and customer experience,
-- and identify core, opportunity and risk categories.
-- =========================================================
CREATE VIEW vw_order_item_enriched AS

SELECT
    oi.order_id,
    oi.order_item_id,

    f.customer_unique_id,

    f.order_status,
    f.order_purchase_timestamp,
    f.purchase_date,
    f.purchase_year,
    f.purchase_year_month,

    f.customer_state,

    oi.product_id,
    oi.seller_id,

    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    p.product_category_name AS category_original,

    oi.price,
    oi.freight_value,

    ROUND(
        oi.price + oi.freight_value,
        2
    ) AS item_gross_value,

    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_photos_qty,

    f.avg_review_score,
    f.delivery_days,
    f.delay_days,
    f.is_delayed

FROM order_items oi

INNER JOIN vw_order_fact f
    ON oi.order_id = f.order_id

LEFT JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN category_translation ct
    ON p.product_category_name =
       ct.product_category_name;




CREATE VIEW vw_category_performance AS

SELECT
    product_category,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT product_id)
        AS products_sold,

    COUNT(DISTINCT order_id)
        AS orders,

    COUNT(DISTINCT customer_unique_id)
        AS customers,

    ROUND(
        SUM(price),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(price + freight_value),
        2
    ) AS gross_value,

    ROUND(
        AVG(price),
        2
    ) AS avg_item_price,

    ROUND(
        SUM(price)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS category_gmv_per_order,

    ROUND(
        SUM(price)
        / NULLIF(COUNT(DISTINCT customer_unique_id), 0),
        2
    ) AS gmv_per_customer,

    ROUND(
        SUM(freight_value)
        / NULLIF(SUM(price), 0)
        * 100,
        2
    ) AS freight_to_gmv_pct

FROM vw_order_item_enriched

WHERE order_status = 'delivered'

GROUP BY product_category;




WITH total AS (

    SELECT
        COUNT(DISTINCT customer_unique_id)
            AS total_customers

    FROM vw_order_item_enriched

    WHERE order_status = 'delivered'
)

SELECT
    c.product_category,
    c.customers,

    ROUND(
        c.customers * 100.0
        / NULLIF(t.total_customers, 0),
        2
    ) AS customer_penetration_pct,

    c.merchandise_gmv

FROM vw_category_performance c

CROSS JOIN total t

ORDER BY customer_penetration_pct DESC;




SELECT
    product_category,
    merchandise_gmv,

    ROUND(
        merchandise_gmv * 100.0
        /
        SUM(merchandise_gmv) OVER (),
        2
    ) AS gmv_share_pct

FROM vw_category_performance

ORDER BY merchandise_gmv DESC;




WITH category_rank AS (

    SELECT
        product_category,
        merchandise_gmv,

        merchandise_gmv
        /
        SUM(merchandise_gmv) OVER ()
        AS gmv_share,

        ROW_NUMBER() OVER (
            ORDER BY merchandise_gmv DESC
        ) AS revenue_rank

    FROM vw_category_performance
),

pareto AS (

    SELECT
        *,

        SUM(gmv_share) OVER (
            ORDER BY revenue_rank
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_gmv_share

    FROM category_rank
)

SELECT
    product_category,

    revenue_rank,

    ROUND(
        merchandise_gmv,
        2
    ) AS merchandise_gmv,

    ROUND(
        gmv_share * 100,
        2
    ) AS gmv_share_pct,

    ROUND(
        cumulative_gmv_share * 100,
        2
    ) AS cumulative_gmv_share_pct

FROM pareto

ORDER BY revenue_rank;




WITH ranked AS (

    SELECT
        product_category,
        merchandise_gmv,

        ROW_NUMBER() OVER (
            ORDER BY merchandise_gmv DESC
        ) AS rn

    FROM vw_category_performance
)

SELECT
    ROUND(
        SUM(
            CASE
                WHEN rn <= 5
                THEN merchandise_gmv
                ELSE 0
            END
        ) * 100.0
        / SUM(merchandise_gmv),
        2
    ) AS top5_gmv_share,

    ROUND(
        SUM(
            CASE
                WHEN rn <= 10
                THEN merchandise_gmv
                ELSE 0
            END
        ) * 100.0
        / SUM(merchandise_gmv),
        2
    ) AS top10_gmv_share

FROM ranked;






CREATE VIEW vw_category_abc AS

WITH category_rank AS (

    SELECT
        product_category,
        merchandise_gmv,

        merchandise_gmv
        /
        SUM(merchandise_gmv) OVER ()
        AS gmv_share,

        ROW_NUMBER() OVER (
            ORDER BY merchandise_gmv DESC
        ) AS revenue_rank

    FROM vw_category_performance
),

cumulative AS (

    SELECT
        *,

        SUM(gmv_share) OVER (
            ORDER BY revenue_rank
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_share

    FROM category_rank
)

SELECT
    product_category,
    revenue_rank,
    merchandise_gmv,

    ROUND(
        gmv_share * 100,
        2
    ) AS gmv_share_pct,

    ROUND(
        cumulative_share * 100,
        2
    ) AS cumulative_gmv_share_pct,

    CASE
        WHEN cumulative_share - gmv_share < 0.80
            THEN 'A - Core'

        WHEN cumulative_share - gmv_share < 0.95
            THEN 'B - Growth'

        ELSE 'C - Long Tail'
    END AS abc_class

FROM cumulative;



CREATE VIEW vw_order_category_review AS

SELECT DISTINCT
    order_id,
    product_category,
    avg_review_score

FROM vw_order_item_enriched

WHERE order_status = 'delivered';



CREATE VIEW vw_category_experience AS

WITH review_metrics AS (

    SELECT
        product_category,

        COUNT(avg_review_score)
            AS reviewed_orders,

        AVG(avg_review_score)
            AS avg_review_score,

        SUM(
            CASE
                WHEN avg_review_score <= 2
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(avg_review_score), 0)
            AS low_rating_rate

    FROM vw_order_category_review

    WHERE avg_review_score IS NOT NULL

    GROUP BY product_category
)

SELECT
    p.*,

    ROUND(
        r.avg_review_score,
        2
    ) AS avg_review_score,

    ROUND(
        r.low_rating_rate,
        2
    ) AS low_rating_rate,

    r.reviewed_orders

FROM vw_category_performance p

LEFT JOIN review_metrics r
    ON p.product_category =
       r.product_category;




WITH benchmarks AS (

    SELECT
        AVG(merchandise_gmv)
            AS avg_category_gmv,

        AVG(avg_review_score)
            AS avg_category_rating

    FROM vw_category_experience

    WHERE avg_review_score IS NOT NULL
)

SELECT
    c.product_category,
    c.merchandise_gmv,
    c.orders,
    c.customers,
    c.avg_review_score,
    c.low_rating_rate,

    CASE

        WHEN c.merchandise_gmv >= b.avg_category_gmv
             AND c.avg_review_score >= b.avg_category_rating
        THEN 'Core Strength'

        WHEN c.merchandise_gmv >= b.avg_category_gmv
             AND c.avg_review_score < b.avg_category_rating
        THEN 'Revenue at Risk'

        WHEN c.merchandise_gmv < b.avg_category_gmv
             AND c.avg_review_score >= b.avg_category_rating
        THEN 'Growth Opportunity'

        ELSE 'Long-tail / Improve'

    END AS portfolio_position

FROM vw_category_experience c

CROSS JOIN benchmarks b

WHERE c.avg_review_score IS NOT NULL

ORDER BY c.merchandise_gmv DESC;





CREATE VIEW vw_category_monthly AS

SELECT
    purchase_year_month AS month,

    product_category,

    COUNT(DISTINCT order_id)
        AS orders,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT customer_unique_id)
        AS customers,

    ROUND(
        SUM(price),
        2
    ) AS merchandise_gmv

FROM vw_order_item_enriched

WHERE order_status = 'delivered'

GROUP BY
    purchase_year_month,
    product_category;




CREATE VIEW vw_product_portfolio_dashboard AS

SELECT
    p.product_category,

    p.units_sold,
    p.products_sold,
    p.orders,
    p.customers,

    p.merchandise_gmv,
    p.freight_value,
    p.gross_value,

    p.avg_item_price,
    p.category_gmv_per_order,
    p.gmv_per_customer,
    p.freight_to_gmv_pct,

    ROUND(
        p.merchandise_gmv * 100.0
        /
        SUM(p.merchandise_gmv) OVER (),
        2
    ) AS gmv_share_pct,

    a.revenue_rank,
    a.cumulative_gmv_share_pct,
    a.abc_class,

    e.avg_review_score,
    e.low_rating_rate

FROM vw_category_performance p

LEFT JOIN vw_category_abc a
    ON p.product_category =
       a.product_category

LEFT JOIN vw_category_experience e
    ON p.product_category =
       e.product_category;