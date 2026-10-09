-- =========================================================
-- 12 Customer Experience Intelligence
-- ---------------------------------------------------------
-- Purpose:
-- Analyze customer review behavior and its association
-- with fulfillment performance, product categories and
-- sellers, and identify customer experience risk.
-- =========================================================
CREATE VIEW vw_order_review_latest AS

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp

FROM (

    SELECT
        r.*,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                review_answer_timestamp DESC,
                review_creation_date DESC,
                review_id DESC
        ) AS rn

    FROM reviews r

) t

WHERE rn = 1;




CREATE VIEW vw_customer_experience_order AS

SELECT
    f.order_id,
    f.customer_unique_id,

    f.purchase_year_month,
    f.customer_state,

    f.merchandise_gmv,
    f.freight_value,
    f.item_count,

    f.approval_hours,
    f.processing_hours,
    f.transit_hours,

    f.delivery_days,
    f.promised_delivery_days,
    f.delay_days,
    f.delivery_status,

    r.review_score,

    CASE
        WHEN r.review_score >= 4
        THEN 'Positive'

        WHEN r.review_score = 3
        THEN 'Neutral'

        WHEN r.review_score <= 2
        THEN 'Negative'

        ELSE 'No Review'
    END AS satisfaction_group,

    CASE
        WHEN r.review_score <= 2 THEN 1
        WHEN r.review_score IS NOT NULL THEN 0
        ELSE NULL
    END AS is_low_rating,

    CASE
        WHEN r.review_score >= 4 THEN 1
        WHEN r.review_score IS NOT NULL THEN 0
        ELSE NULL
    END AS is_high_rating,

    CASE
        WHEN f.delay_days IS NULL
        THEN 'Unknown'

        WHEN f.delay_days <= 0
        THEN 'Not Late'

        WHEN f.delay_days <= 3
        THEN '1-3 Days Late'

        WHEN f.delay_days <= 7
        THEN '4-7 Days Late'

        WHEN f.delay_days <= 14
        THEN '8-14 Days Late'

        ELSE '15+ Days Late'
    END AS delay_severity

FROM vw_fulfillment_order f

LEFT JOIN vw_order_review_latest r
    ON f.order_id = r.order_id;



SELECT
    COUNT(*) AS delivered_orders,

    COUNT(review_score) AS reviewed_orders,

    ROUND(
        COUNT(review_score) * 100.0
        / COUNT(*),
        2
    ) AS review_coverage_rate,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_high_rating) * 100,
        2
    ) AS positive_rating_rate,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate

FROM vw_customer_experience_order;



SELECT
    review_score,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS review_share_pct

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL

GROUP BY review_score

ORDER BY review_score;



SELECT
    satisfaction_group,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL

GROUP BY satisfaction_group;




SELECT
    satisfaction_group,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL

GROUP BY satisfaction_group;



WITH experience AS (

    SELECT
        CASE
            WHEN delivery_status = 'Late'
            THEN 'Late'

            ELSE 'Not Late'
        END AS fulfillment_group,

        AVG(is_low_rating) AS low_rating_rate

    FROM vw_customer_experience_order

    WHERE review_score IS NOT NULL
      AND delivery_status IS NOT NULL

    GROUP BY
        CASE
            WHEN delivery_status = 'Late'
            THEN 'Late'
            ELSE 'Not Late'
        END
)

SELECT
    ROUND(
        MAX(
            CASE
                WHEN fulfillment_group = 'Late'
                THEN low_rating_rate
            END
        )
        /
        NULLIF(
            MAX(
                CASE
                    WHEN fulfillment_group = 'Not Late'
                    THEN low_rating_rate
                END
            ),
            0
        ),
        2
    ) AS low_rating_risk_ratio

FROM experience;



WITH experience AS (

    SELECT
        CASE
            WHEN delivery_status = 'Late'
            THEN 'Late'

            ELSE 'Not Late'
        END AS fulfillment_group,

        AVG(is_low_rating) AS low_rating_rate

    FROM vw_customer_experience_order

    WHERE review_score IS NOT NULL
      AND delivery_status IS NOT NULL

    GROUP BY
        CASE
            WHEN delivery_status = 'Late'
            THEN 'Late'
            ELSE 'Not Late'
        END
)

SELECT
    ROUND(
        MAX(
            CASE
                WHEN fulfillment_group = 'Late'
                THEN low_rating_rate
            END
        )
        /
        NULLIF(
            MAX(
                CASE
                    WHEN fulfillment_group = 'Not Late'
                    THEN low_rating_rate
                END
            ),
            0
        ),
        2
    ) AS low_rating_risk_ratio

FROM experience;



SELECT
    delay_severity,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate,

    ROUND(
        AVG(is_high_rating) * 100,
        2
    ) AS positive_rating_rate

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL
  AND delay_severity <> 'Unknown'

GROUP BY delay_severity

ORDER BY
    CASE delay_severity
        WHEN 'Not Late' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8-14 Days Late' THEN 4
        WHEN '15+ Days Late' THEN 5
    END;



SELECT
    CASE
        WHEN delivery_days <= 3
        THEN '0-3 Days'

        WHEN delivery_days <= 7
        THEN '4-7 Days'

        WHEN delivery_days <= 14
        THEN '8-14 Days'

        WHEN delivery_days <= 21
        THEN '15-21 Days'

        WHEN delivery_days <= 30
        THEN '22-30 Days'

        ELSE '31+ Days'
    END AS delivery_band,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL
  AND delivery_days IS NOT NULL
  AND delivery_days >= 0

GROUP BY
    CASE
        WHEN delivery_days <= 3 THEN '0-3 Days'
        WHEN delivery_days <= 7 THEN '4-7 Days'
        WHEN delivery_days <= 14 THEN '8-14 Days'
        WHEN delivery_days <= 21 THEN '15-21 Days'
        WHEN delivery_days <= 30 THEN '22-30 Days'
        ELSE '31+ Days'
    END

ORDER BY MIN(delivery_days);



SELECT
    satisfaction_group,

    COUNT(*) AS orders,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(merchandise_gmv) * 100.0
        /
        SUM(
            SUM(merchandise_gmv)
        ) OVER (),
        2
    ) AS gmv_share_pct

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL

GROUP BY satisfaction_group;



SELECT
    ROUND(
        SUM(
            CASE
                WHEN delivery_status = 'Late'
                 AND is_low_rating = 1
                THEN merchandise_gmv
                ELSE 0
            END
        ),
        2
    ) AS late_low_rating_gmv,

    ROUND(
        SUM(
            CASE
                WHEN delivery_status = 'Late'
                 AND is_low_rating = 1
                THEN merchandise_gmv
                ELSE 0
            END
        ) * 100.0
        /
        NULLIF(SUM(merchandise_gmv), 0),
        2
    ) AS late_low_rating_gmv_share

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL;




CREATE VIEW vw_experience_diagnosis AS

SELECT
    *,

    CASE

        WHEN delivery_status IN ('Early', 'On Time')
             AND review_score >= 4
        THEN 'Healthy Experience'

        WHEN delivery_status = 'Late'
             AND review_score <= 2
        THEN 'Fulfillment-Related Risk'

        WHEN delivery_status IN ('Early', 'On Time')
             AND review_score <= 2
        THEN 'Non-Fulfillment Experience Risk'

        WHEN delivery_status = 'Late'
             AND review_score >= 4
        THEN 'Late but Satisfied'

        ELSE 'Neutral / Mixed'

    END AS experience_diagnosis

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL;



SELECT
    experience_diagnosis,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(merchandise_gmv) * 100.0
        /
        SUM(
            SUM(merchandise_gmv)
        ) OVER (),
        2
    ) AS gmv_share_pct

FROM vw_experience_diagnosis

GROUP BY experience_diagnosis

ORDER BY orders DESC;





CREATE VIEW vw_experience_monthly AS

SELECT
    purchase_year_month AS month,

    COUNT(review_score)
        AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate,

    ROUND(
        AVG(is_high_rating) * 100,
        2
    ) AS positive_rating_rate,

    ROUND(
        SUM(
            CASE
                WHEN delivery_status = 'Late'
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(delivery_status), 0),
        2
    ) AS delay_rate

FROM vw_customer_experience_order

GROUP BY purchase_year_month;





CREATE VIEW vw_order_category_experience AS

SELECT DISTINCT
    i.order_id,
    i.product_category,
    e.review_score,
    e.is_low_rating,
    e.delivery_status,
    e.delay_days

FROM vw_order_item_enriched i

INNER JOIN vw_customer_experience_order e
    ON i.order_id = e.order_id

WHERE i.order_status = 'delivered'
  AND e.review_score IS NOT NULL;



SELECT
    product_category,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate,

    ROUND(
        SUM(
            CASE
                WHEN delivery_status = 'Late'
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(delivery_status), 0),
        2
    ) AS delay_rate

FROM vw_order_category_experience

GROUP BY product_category

HAVING COUNT(*) >= 100

ORDER BY low_rating_rate DESC;




CREATE VIEW vw_seller_experience_latest AS

SELECT
    s.seller_id,

    COUNT(*) AS reviewed_seller_orders,

    ROUND(
        AVG(e.review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(e.is_low_rating) * 100,
        2
    ) AS low_rating_rate,

    ROUND(
        AVG(e.is_high_rating) * 100,
        2
    ) AS positive_rating_rate,

    ROUND(
        SUM(
            CASE
                WHEN e.delivery_status = 'Late'
                THEN 1 ELSE 0
            END
        ) * 100.0
        /
        NULLIF(COUNT(e.delivery_status), 0),
        2
    ) AS delay_rate

FROM vw_order_seller s

INNER JOIN vw_customer_experience_order e
    ON s.order_id = e.order_id

WHERE s.order_status = 'delivered'
  AND e.review_score IS NOT NULL

GROUP BY s.seller_id;



SELECT
    c.seller_id,

    c.orders,
    c.merchandise_gmv,

    e.avg_review_score,
    e.low_rating_rate,
    e.delay_rate

FROM vw_seller_commercial c

INNER JOIN vw_seller_experience_latest e
    ON c.seller_id = e.seller_id

WHERE c.orders >= 50

ORDER BY
    c.merchandise_gmv DESC,
    e.low_rating_rate DESC;



SELECT
    CASE

        WHEN merchandise_gmv = 0
        THEN 'Undefined'

        WHEN freight_value
             / merchandise_gmv < 0.10
        THEN '<10%'

        WHEN freight_value
             / merchandise_gmv < 0.20
        THEN '10-20%'

        WHEN freight_value
             / merchandise_gmv < 0.30
        THEN '20-30%'

        WHEN freight_value
             / merchandise_gmv < 0.50
        THEN '30-50%'

        ELSE '50%+'

    END AS freight_burden_band,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score,

    ROUND(
        AVG(is_low_rating) * 100,
        2
    ) AS low_rating_rate

FROM vw_customer_experience_order

WHERE review_score IS NOT NULL
  AND merchandise_gmv > 0

GROUP BY
    CASE
        WHEN merchandise_gmv = 0 THEN 'Undefined'
        WHEN freight_value / merchandise_gmv < 0.10 THEN '<10%'
        WHEN freight_value / merchandise_gmv < 0.20 THEN '10-20%'
        WHEN freight_value / merchandise_gmv < 0.30 THEN '20-30%'
        WHEN freight_value / merchandise_gmv < 0.50 THEN '30-50%'
        ELSE '50%+'
    END

ORDER BY MIN(
    freight_value / NULLIF(merchandise_gmv, 0)
);




CREATE VIEW vw_customer_experience_dashboard AS

SELECT
    e.order_id,
    e.customer_unique_id,

    e.purchase_year_month,
    e.customer_state,

    e.merchandise_gmv,
    e.freight_value,
    e.item_count,

    e.delivery_days,
    e.promised_delivery_days,
    e.delay_days,
    e.delivery_status,
    e.delay_severity,

    e.review_score,
    e.satisfaction_group,
    e.is_low_rating,
    e.is_high_rating,

    d.experience_diagnosis

FROM vw_customer_experience_order e

LEFT JOIN vw_experience_diagnosis d
    ON e.order_id = d.order_id;