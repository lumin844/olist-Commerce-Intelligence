-- =========================================================
-- 08 RFM Customer Segmentation
-- ---------------------------------------------------------
-- Purpose:
-- Segment customers based on Recency, Frequency and
-- Monetary value to support customer value management.
-- =========================================================
CREATE VIEW vw_rfm_base AS

SELECT
    f.customer_unique_id,

    s.analysis_date,

    MIN(DATE(f.order_purchase_timestamp))
        AS first_purchase_date,

    MAX(DATE(f.order_purchase_timestamp))
        AS last_purchase_date,

    DATEDIFF(
        s.analysis_date,
        MAX(DATE(f.order_purchase_timestamp))
    ) AS recency_days,

    COUNT(DISTINCT f.order_id)
        AS frequency,

    ROUND(
        SUM(f.merchandise_gmv),
        2
    ) AS monetary_value,

    ROUND(
        SUM(f.merchandise_gmv)
        /
        NULLIF(COUNT(DISTINCT f.order_id), 0),
        2
    ) AS avg_order_value

FROM vw_order_fact f

CROSS JOIN (
    SELECT
        DATE_ADD(
            MAX(DATE(order_purchase_timestamp)),
            INTERVAL 1 DAY
        ) AS analysis_date
    FROM vw_order_fact
    WHERE order_status = 'delivered'
) s

WHERE f.order_status = 'delivered'
  AND f.customer_unique_id IS NOT NULL

GROUP BY
    f.customer_unique_id,
    s.analysis_date;




CREATE VIEW vw_rfm_scored AS

WITH ranked AS (

    SELECT
        *,

        PERCENT_RANK() OVER (
            ORDER BY recency_days DESC
        ) AS recency_percentile,

        PERCENT_RANK() OVER (
            ORDER BY monetary_value ASC
        ) AS monetary_percentile

    FROM vw_rfm_base
),

scored AS (

    SELECT
        *,

        -- Recency:
        -- 越近期购买，得分越高
        CASE
            WHEN recency_percentile <= 0.20 THEN 1
            WHEN recency_percentile <= 0.40 THEN 2
            WHEN recency_percentile <= 0.60 THEN 3
            WHEN recency_percentile <= 0.80 THEN 4
            ELSE 5
        END AS r_score,

        -- Frequency:
        -- 不使用NTILE，避免相同购买次数被强行拆分
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency = 4 THEN 4
            ELSE 5
        END AS f_score,

        -- Monetary:
        -- 消费越高，得分越高
        CASE
            WHEN monetary_percentile <= 0.20 THEN 1
            WHEN monetary_percentile <= 0.40 THEN 2
            WHEN monetary_percentile <= 0.60 THEN 3
            WHEN monetary_percentile <= 0.80 THEN 4
            ELSE 5
        END AS m_score

    FROM ranked
)

SELECT
    customer_unique_id,

    analysis_date,
    first_purchase_date,
    last_purchase_date,

    recency_days,
    frequency,
    monetary_value,
    avg_order_value,

    r_score,
    f_score,
    m_score,

    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_code,

    r_score
    + f_score
    + m_score AS rfm_total_score

FROM scored;




CREATE VIEW vw_rfm_segments AS

SELECT
    *,

    CASE

        WHEN r_score >= 4
             AND f_score >= 3
             AND m_score >= 4
        THEN 'Champions'

        WHEN r_score = 1
             AND f_score >= 3
             AND m_score >= 4
        THEN 'Cannot Lose Them'

        WHEN r_score <= 2
             AND f_score >= 2
             AND m_score >= 4
        THEN 'High-Value At Risk'

        WHEN r_score >= 3
             AND f_score >= 2
        THEN 'Loyal Customers'

        WHEN r_score >= 4
             AND f_score = 2
        THEN 'Potential Loyalists'

        WHEN r_score = 5
             AND f_score = 1
        THEN 'New Customers'

        WHEN r_score = 4
             AND f_score = 1
        THEN 'Promising'

        WHEN r_score <= 2
             AND f_score = 1
        THEN 'Hibernating'

        ELSE 'Need Attention'

    END AS customer_segment,

    CASE
        WHEN m_score >= 4 THEN 'High Value'
        WHEN m_score = 3 THEN 'Medium Value'
        ELSE 'Lower Value'
    END AS value_tier

FROM vw_rfm_scored;




SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM vw_rfm_segments

GROUP BY customer_segment

ORDER BY customers DESC;



SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS total_gmv,

    ROUND(
        SUM(monetary_value)
        * 100.0
        /
        SUM(
            SUM(monetary_value)
        ) OVER (),
        2
    ) AS gmv_share_pct,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_customer_value,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_frequency,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    ROUND(
        AVG(avg_order_value),
        2
    ) AS avg_order_value

FROM vw_rfm_segments

GROUP BY customer_segment

ORDER BY total_gmv DESC;



SELECT
    value_tier,

    COUNT(*) AS customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct,

    ROUND(
        SUM(monetary_value),
        2
    ) AS total_gmv

FROM vw_rfm_segments

GROUP BY value_tier

ORDER BY total_gmv DESC;



SELECT
    r_score,
    f_score,

    COUNT(*) AS customers,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_customer_value

FROM vw_rfm_segments

GROUP BY
    r_score,
    f_score

ORDER BY
    r_score,
    f_score;


SELECT
    customer_unique_id,

    recency_days,
    frequency,
    monetary_value,
    avg_order_value,

    r_score,
    f_score,
    m_score,

    customer_segment

FROM vw_rfm_segments

WHERE customer_segment IN (
    'High-Value At Risk',
    'Cannot Lose Them'
)

ORDER BY monetary_value DESC

LIMIT 50;



SELECT
    COUNT(*) AS champion_customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS champion_gmv,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_champion_value,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_champion_frequency,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_champion_recency

FROM vw_rfm_segments

WHERE customer_segment = 'Champions';





CREATE VIEW vw_customer_rfm_dashboard AS

SELECT
    customer_unique_id,

    first_purchase_date,
    last_purchase_date,

    recency_days,
    frequency,
    monetary_value,
    avg_order_value,

    r_score,
    f_score,
    m_score,

    rfm_code,
    rfm_total_score,

    customer_segment,
    value_tier

FROM vw_rfm_segments;