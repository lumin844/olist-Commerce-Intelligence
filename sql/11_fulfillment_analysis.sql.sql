-- =========================================================
-- 11 Fulfillment Intelligence
-- ---------------------------------------------------------
-- Purpose:
-- Analyze the full order fulfillment lifecycle from
-- purchase to delivery, identify delay patterns and
-- locate potential operational bottlenecks.
-- =========================================================
CREATE VIEW vw_fulfillment_order AS

SELECT
    order_id,
    customer_unique_id,

    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    purchase_year_month,
    customer_state,

    merchandise_gmv,
    freight_value,
    item_count,

    avg_review_score,

    -- 下单 → 支付确认
    CASE
        WHEN order_approved_at IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            order_purchase_timestamp,
            order_approved_at
        )
    END AS approval_hours,

    -- 支付确认 → 交给承运商
    CASE
        WHEN order_approved_at IS NOT NULL
         AND order_delivered_carrier_date IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            order_approved_at,
            order_delivered_carrier_date
        )
    END AS processing_hours,

    -- 承运商接收 → 客户收货
    CASE
        WHEN order_delivered_carrier_date IS NOT NULL
         AND order_delivered_customer_date IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_delivered_customer_date
        )
    END AS transit_hours,

    -- 下单 → 客户收货
    CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            order_purchase_timestamp,
            order_delivered_customer_date
        )
    END AS total_delivery_hours,

    -- 总配送天数
    CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        )
    END AS delivery_days,

    -- 平台承诺给客户的预计时长
    DATEDIFF(
        order_estimated_delivery_date,
        order_purchase_timestamp
    ) AS promised_delivery_days,

    -- 正数=迟到；负数=提前
    CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
    END AS delay_days,

    CASE
        WHEN order_delivered_customer_date IS NULL
        THEN NULL

        WHEN DATE(order_delivered_customer_date)
             < DATE(order_estimated_delivery_date)
        THEN 'Early'

        WHEN DATE(order_delivered_customer_date)
             = DATE(order_estimated_delivery_date)
        THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status,

    -- 是否存在完整且符合先后顺序的流程时间
    CASE
        WHEN order_approved_at IS NOT NULL
         AND order_delivered_carrier_date IS NOT NULL
         AND order_delivered_customer_date IS NOT NULL
         AND order_purchase_timestamp <= order_approved_at
         AND order_approved_at <= order_delivered_carrier_date
         AND order_delivered_carrier_date <= order_delivered_customer_date
        THEN 1
        ELSE 0
    END AS valid_timeline

FROM vw_order_fact

WHERE order_status = 'delivered';



SELECT
    COUNT(*) AS delivered_orders,

    COUNT(delivery_days)
        AS orders_with_delivery_data,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(promised_delivery_days),
        2
    ) AS avg_promised_delivery_days,

    ROUND(
        AVG(delay_days),
        2
    ) AS avg_delay_days,

    SUM(
        CASE
            WHEN delivery_status = 'Late'
            THEN 1 ELSE 0
        END
    ) AS late_orders,

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
    ) AS late_delivery_rate

FROM vw_fulfillment_order;



SELECT
    COUNT(*) AS valid_orders,

    ROUND(
        AVG(approval_hours),
        2
    ) AS avg_approval_hours,

    ROUND(
        AVG(processing_hours),
        2
    ) AS avg_processing_hours,

    ROUND(
        AVG(transit_hours),
        2
    ) AS avg_transit_hours,

    ROUND(
        AVG(total_delivery_hours),
        2
    ) AS avg_total_delivery_hours

FROM vw_fulfillment_order

WHERE valid_timeline = 1;



SELECT
    ROUND(
        AVG(approval_hours) / 24,
        2
    ) AS avg_approval_days,

    ROUND(
        AVG(processing_hours) / 24,
        2
    ) AS avg_processing_days,

    ROUND(
        AVG(transit_hours) / 24,
        2
    ) AS avg_transit_days,

    ROUND(
        AVG(total_delivery_hours) / 24,
        2
    ) AS avg_total_delivery_days

FROM vw_fulfillment_order

WHERE valid_timeline = 1;



WITH stage_time AS (

    SELECT
        AVG(approval_hours)
            AS approval_hours,

        AVG(processing_hours)
            AS processing_hours,

        AVG(transit_hours)
            AS transit_hours

    FROM vw_fulfillment_order

    WHERE valid_timeline = 1
)

SELECT
    ROUND(
        approval_hours * 100.0
        /
        NULLIF(
            approval_hours
            + processing_hours
            + transit_hours,
            0
        ),
        2
    ) AS approval_share_pct,

    ROUND(
        processing_hours * 100.0
        /
        NULLIF(
            approval_hours
            + processing_hours
            + transit_hours,
            0
        ),
        2
    ) AS processing_share_pct,

    ROUND(
        transit_hours * 100.0
        /
        NULLIF(
            approval_hours
            + processing_hours
            + transit_hours,
            0
        ),
        2
    ) AS transit_share_pct

FROM stage_time;



SELECT
    CASE
        WHEN delivery_days <= 3
            THEN '0-3 days'

        WHEN delivery_days <= 7
            THEN '4-7 days'

        WHEN delivery_days <= 14
            THEN '8-14 days'

        WHEN delivery_days <= 21
            THEN '15-21 days'

        WHEN delivery_days <= 30
            THEN '22-30 days'

        ELSE '31+ days'
    END AS delivery_band,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_fulfillment_order

WHERE delivery_days IS NOT NULL
  AND delivery_days >= 0

GROUP BY
    CASE
        WHEN delivery_days <= 3 THEN '0-3 days'
        WHEN delivery_days <= 7 THEN '4-7 days'
        WHEN delivery_days <= 14 THEN '8-14 days'
        WHEN delivery_days <= 21 THEN '15-21 days'
        WHEN delivery_days <= 30 THEN '22-30 days'
        ELSE '31+ days'
    END

ORDER BY MIN(delivery_days);




SELECT
    delivery_status,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_fulfillment_order

WHERE delivery_status IS NOT NULL

GROUP BY delivery_status

ORDER BY
    CASE delivery_status
        WHEN 'Early' THEN 1
        WHEN 'On Time' THEN 2
        WHEN 'Late' THEN 3
    END;



SELECT
    CASE
        WHEN delay_days <= 0
            THEN 'Not Late'

        WHEN delay_days <= 3
            THEN '1-3 days late'

        WHEN delay_days <= 7
            THEN '4-7 days late'

        WHEN delay_days <= 14
            THEN '8-14 days late'

        ELSE '15+ days late'
    END AS delay_severity,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_fulfillment_order

WHERE delay_days IS NOT NULL

GROUP BY
    CASE
        WHEN delay_days <= 0 THEN 'Not Late'
        WHEN delay_days <= 3 THEN '1-3 days late'
        WHEN delay_days <= 7 THEN '4-7 days late'
        WHEN delay_days <= 14 THEN '8-14 days late'
        ELSE '15+ days late'
    END

ORDER BY
    MIN(
        CASE
            WHEN delay_days <= 0 THEN 0
            ELSE delay_days
        END
    );



SELECT
    CASE
        WHEN promised_delivery_days <= 7
            THEN '0-7 days'

        WHEN promised_delivery_days <= 14
            THEN '8-14 days'

        WHEN promised_delivery_days <= 21
            THEN '15-21 days'

        WHEN promised_delivery_days <= 30
            THEN '22-30 days'

        ELSE '31+ days'
    END AS promise_band,

    COUNT(*) AS orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_actual_delivery_days,

    ROUND(
        AVG(promised_delivery_days),
        2
    ) AS avg_promised_delivery_days,

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
    ) AS late_rate

FROM vw_fulfillment_order

WHERE promised_delivery_days >= 0
  AND delivery_days IS NOT NULL

GROUP BY
    CASE
        WHEN promised_delivery_days <= 7 THEN '0-7 days'
        WHEN promised_delivery_days <= 14 THEN '8-14 days'
        WHEN promised_delivery_days <= 21 THEN '15-21 days'
        WHEN promised_delivery_days <= 30 THEN '22-30 days'
        ELSE '31+ days'
    END

ORDER BY MIN(promised_delivery_days);



SELECT
    ROUND(
        AVG(
            promised_delivery_days
            - delivery_days
        ),
        2
    ) AS avg_delivery_buffer_days

FROM vw_fulfillment_order

WHERE delivery_days IS NOT NULL;




CREATE VIEW vw_fulfillment_monthly AS

SELECT
    purchase_year_month AS month,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(promised_delivery_days),
        2
    ) AS avg_promised_delivery_days,

    ROUND(
        AVG(delay_days),
        2
    ) AS avg_delay_days,

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
    ) AS late_rate

FROM vw_fulfillment_order

GROUP BY purchase_year_month;



SELECT
    g.month,

    g.orders,
    g.merchandise_gmv,

    f.avg_delivery_days,
    f.late_rate

FROM vw_monthly_performance g

LEFT JOIN vw_fulfillment_monthly f
    ON g.month = f.month

ORDER BY g.month;



SELECT
    customer_state,

    COUNT(*) AS orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(delay_days),
        2
    ) AS avg_delay_days,

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
    ) AS late_rate

FROM vw_fulfillment_order

WHERE customer_state IS NOT NULL

GROUP BY customer_state

HAVING COUNT(*) >= 100

ORDER BY avg_delivery_days DESC;




CREATE VIEW vw_state_fulfillment AS

SELECT
    customer_state,

    COUNT(*) AS orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(promised_delivery_days),
        2
    ) AS avg_promised_delivery_days,

    ROUND(
        AVG(delay_days),
        2
    ) AS avg_delay_days,

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
    ) AS late_rate

FROM vw_fulfillment_order

WHERE customer_state IS NOT NULL

GROUP BY customer_state;




CREATE VIEW vw_order_category_fulfillment AS

SELECT DISTINCT
    order_id,
    product_category,

    delivery_days,
    delay_days,
    is_delayed

FROM vw_order_item_enriched

WHERE order_status = 'delivered';



SELECT
    order_id,
    customer_state,

    merchandise_gmv,
    freight_value,

    delivery_days,
    promised_delivery_days,
    delay_days,

    avg_review_score

FROM vw_fulfillment_order

WHERE delay_days > 0

ORDER BY delay_days DESC

LIMIT 50;





CREATE VIEW vw_fulfillment_risk AS

SELECT
    *,

    CASE
        WHEN delay_days IS NULL
        THEN 'Unknown'

        WHEN delay_days <= 0
        THEN 'On Track'

        WHEN delay_days <= 3
        THEN 'Minor Delay'

        WHEN delay_days <= 7
        THEN 'Moderate Delay'

        WHEN delay_days <= 14
        THEN 'Severe Delay'

        ELSE 'Critical Delay'
    END AS fulfillment_risk_level

FROM vw_fulfillment_order;



SELECT
    fulfillment_risk_level,

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

FROM vw_fulfillment_risk

GROUP BY fulfillment_risk_level;





CREATE VIEW vw_fulfillment_dashboard AS

SELECT
    order_id,
    customer_unique_id,

    purchase_year_month,
    customer_state,

    merchandise_gmv,
    freight_value,
    item_count,

    approval_hours,
    processing_hours,
    transit_hours,
    total_delivery_hours,

    delivery_days,
    promised_delivery_days,
    delay_days,

    delivery_status,
    valid_timeline,

    CASE
        WHEN delay_days IS NULL
        THEN 'Unknown'

        WHEN delay_days <= 0
        THEN 'On Track'

        WHEN delay_days <= 3
        THEN 'Minor Delay'

        WHEN delay_days <= 7
        THEN 'Moderate Delay'

        WHEN delay_days <= 14
        THEN 'Severe Delay'

        ELSE 'Critical Delay'
    END AS fulfillment_risk_level,

    avg_review_score

FROM vw_fulfillment_order;