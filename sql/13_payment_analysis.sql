-- =========================================================
-- 13 Payment Behavior Intelligence
-- ---------------------------------------------------------
-- Purpose:
-- Analyze payment method structure, mixed payment behavior,
-- installment usage and the relationship between payment
-- behavior and order value.
-- =========================================================

CREATE VIEW vw_payment_enriched AS

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,

    f.customer_unique_id,
    f.order_status,
    f.order_purchase_timestamp,
    f.purchase_year_month,
    f.customer_state,

    f.merchandise_gmv,
    f.freight_value,
    f.gross_order_value

FROM payments p

INNER JOIN vw_order_fact f
    ON p.order_id = f.order_id;




CREATE VIEW vw_order_payment_method AS

SELECT
    order_id,
    payment_type,

    COUNT(*) AS payment_records,

    ROUND(
        SUM(payment_value),
        2
    ) AS payment_method_value,

    MAX(payment_installments)
        AS max_installments

FROM payments

GROUP BY
    order_id,
    payment_type;



SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id)
        AS orders_using_method,

    ROUND(
        SUM(payment_value),
        2
    ) AS payment_value,

    ROUND(
        SUM(payment_value) * 100.0
        /
        SUM(SUM(payment_value)) OVER (),
        2
    ) AS payment_value_share_pct

FROM vw_payment_enriched

WHERE order_status = 'delivered'

GROUP BY payment_type

ORDER BY payment_value DESC;




WITH total AS (

    SELECT
        COUNT(DISTINCT order_id)
            AS total_orders
    FROM vw_order_fact
    WHERE order_status = 'delivered'
)

SELECT
    p.payment_type,

    COUNT(DISTINCT p.order_id)
        AS orders_using_method,

    ROUND(
        COUNT(DISTINCT p.order_id) * 100.0
        / t.total_orders,
        2
    ) AS order_reach_pct

FROM vw_payment_enriched p

CROSS JOIN total t

WHERE p.order_status = 'delivered'

GROUP BY
    p.payment_type,
    t.total_orders

ORDER BY orders_using_method DESC;



SELECT
    CASE
        WHEN payment_method_count = 1
        THEN 'Single Method'

        WHEN payment_method_count >= 2
        THEN 'Mixed Payment'
    END AS payment_structure,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND payment_method_count IS NOT NULL

GROUP BY
    CASE
        WHEN payment_method_count = 1
        THEN 'Single Method'
        ELSE 'Mixed Payment'
    END;




SELECT
    payment_methods,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM vw_order_fact

WHERE order_status = 'delivered'
  AND payment_methods IS NOT NULL

GROUP BY payment_methods

ORDER BY orders DESC;




CREATE VIEW vw_primary_payment_method AS

SELECT
    order_id,
    payment_type AS primary_payment_method,
    payment_method_value AS primary_payment_value

FROM (

    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                payment_method_value DESC,
                payment_type
        ) AS rn

    FROM vw_order_payment_method

) t

WHERE rn = 1;





CREATE VIEW vw_order_payment_profile AS

SELECT
    f.order_id,
    f.customer_unique_id,

    f.purchase_year_month,
    f.customer_state,

    f.merchandise_gmv,
    f.freight_value,
    f.gross_order_value,

    p.total_payment_value,
    p.payment_record_count,
    p.payment_method_count,
    p.payment_methods,

    pm.primary_payment_method,
    pm.primary_payment_value,

    ROUND(
        p.total_payment_value
        - f.gross_order_value,
        2
    ) AS payment_difference,

    CASE
        WHEN p.payment_method_count = 1
        THEN 'Single Method'
        ELSE 'Mixed Payment'
    END AS payment_structure

FROM vw_order_fact f

LEFT JOIN vw_payment_summary p
    ON f.order_id = p.order_id

LEFT JOIN vw_primary_payment_method pm
    ON f.order_id = pm.order_id

WHERE f.order_status = 'delivered';



SELECT
    primary_payment_method,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct,

    ROUND(
        AVG(total_payment_value),
        2
    ) AS avg_payment_value,

    ROUND(
        AVG(gross_order_value),
        2
    ) AS avg_gross_order_value

FROM vw_order_payment_profile

WHERE primary_payment_method IS NOT NULL

GROUP BY primary_payment_method

ORDER BY orders DESC;



SELECT
    COUNT(*) AS orders_with_payment,

    SUM(
        CASE
            WHEN ABS(payment_difference) <= 0.01
            THEN 1 ELSE 0
        END
    ) AS matched_orders,

    SUM(
        CASE
            WHEN ABS(payment_difference) > 0.01
            THEN 1 ELSE 0
        END
    ) AS unmatched_orders,

    ROUND(
        AVG(payment_difference),
        4
    ) AS avg_payment_difference,

    ROUND(
        MAX(ABS(payment_difference)),
        2
    ) AS max_absolute_difference

FROM vw_order_payment_profile

WHERE total_payment_value IS NOT NULL;




SELECT
    ROUND(
        SUM(
            CASE
                WHEN ABS(payment_difference) <= 0.01
                THEN 1 ELSE 0
            END
        ) * 100.0
        / COUNT(*),
        2
    ) AS reconciliation_match_rate

FROM vw_order_payment_profile

WHERE total_payment_value IS NOT NULL;





CREATE VIEW vw_credit_card_order AS

SELECT
    p.order_id,

    ROUND(
        SUM(p.payment_value),
        2
    ) AS credit_card_payment_value,

    MAX(p.payment_installments)
        AS installments

FROM payments p

INNER JOIN vw_order_fact f
    ON p.order_id = f.order_id

WHERE f.order_status = 'delivered'
  AND p.payment_type = 'credit_card'

GROUP BY p.order_id;



SELECT
    installments,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct,

    ROUND(
        AVG(credit_card_payment_value),
        2
    ) AS avg_credit_card_value

FROM vw_credit_card_order

WHERE installments > 0

GROUP BY installments

ORDER BY installments;




SELECT
    CASE
        WHEN installments = 1
        THEN '1 - Full Payment'

        WHEN installments BETWEEN 2 AND 3
        THEN '2-3'

        WHEN installments BETWEEN 4 AND 6
        THEN '4-6'

        WHEN installments BETWEEN 7 AND 9
        THEN '7-9'

        ELSE '10+'
    END AS installment_band,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct,

    ROUND(
        AVG(credit_card_payment_value),
        2
    ) AS avg_credit_card_payment_value

FROM vw_credit_card_order

WHERE installments >= 1

GROUP BY
    CASE
        WHEN installments = 1 THEN '1 - Full Payment'
        WHEN installments BETWEEN 2 AND 3 THEN '2-3'
        WHEN installments BETWEEN 4 AND 6 THEN '4-6'
        WHEN installments BETWEEN 7 AND 9 THEN '7-9'
        ELSE '10+'
    END

ORDER BY MIN(installments);




SELECT
    c.installments,

    COUNT(*) AS orders,

    ROUND(
        AVG(f.gross_order_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(c.credit_card_payment_value),
        2
    ) AS avg_credit_card_payment

FROM vw_credit_card_order c

INNER JOIN vw_order_fact f
    ON c.order_id = f.order_id

WHERE c.installments >= 1

GROUP BY c.installments

ORDER BY c.installments;



WITH credit_orders AS (

    SELECT
        c.order_id,
        c.installments,
        c.credit_card_payment_value,
        f.gross_order_value,

        NTILE(4) OVER (
            ORDER BY f.gross_order_value
        ) AS order_value_quartile

    FROM vw_credit_card_order c

    INNER JOIN vw_order_fact f
        ON c.order_id = f.order_id

    WHERE c.installments >= 1
)

SELECT
    order_value_quartile,

    COUNT(*) AS orders,

    ROUND(
        MIN(gross_order_value),
        2
    ) AS min_order_value,

    ROUND(
        MAX(gross_order_value),
        2
    ) AS max_order_value,

    ROUND(
        AVG(gross_order_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(installments),
        2
    ) AS avg_installments,

    ROUND(
        AVG(
            CASE
                WHEN installments >= 2
                THEN 1 ELSE 0
            END
        ) * 100,
        2
    ) AS installment_usage_rate

FROM credit_orders

GROUP BY order_value_quartile

ORDER BY order_value_quartile;




SELECT
    primary_payment_method,

    COUNT(*) AS orders,

    ROUND(
        AVG(gross_order_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(total_payment_value),
        2
    ) AS avg_payment_value,

    ROUND(
        AVG(merchandise_gmv),
        2
    ) AS avg_merchandise_value,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight

FROM vw_order_payment_profile

WHERE primary_payment_method IS NOT NULL

GROUP BY primary_payment_method

ORDER BY avg_order_value DESC;





WITH order_value_segment AS (

    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY gross_order_value
        ) AS value_quartile

    FROM vw_order_payment_profile

    WHERE primary_payment_method IS NOT NULL
      AND gross_order_value > 0
)

SELECT
    value_quartile,
    primary_payment_method,

    COUNT(*) AS orders,

    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER (
            PARTITION BY value_quartile
        ),
        2
    ) AS payment_method_share_pct

FROM order_value_segment

GROUP BY
    value_quartile,
    primary_payment_method

ORDER BY
    value_quartile,
    orders DESC;





CREATE VIEW vw_payment_monthly AS

SELECT
    f.purchase_year_month AS month,
    p.payment_type,

    COUNT(DISTINCT p.order_id)
        AS orders_using_method,

    ROUND(
        SUM(p.payment_value),
        2
    ) AS payment_value

FROM payments p

INNER JOIN vw_order_fact f
    ON p.order_id = f.order_id

WHERE f.order_status = 'delivered'

GROUP BY
    f.purchase_year_month,
    p.payment_type;



SELECT
    month,
    payment_type,
    payment_value,

    ROUND(
        payment_value * 100.0
        /
        SUM(payment_value) OVER (
            PARTITION BY month
        ),
        2
    ) AS monthly_payment_share_pct

FROM vw_payment_monthly

ORDER BY
    month,
    payment_value DESC;




SELECT
    payment_structure,

    COUNT(*) AS orders,

    ROUND(
        AVG(gross_order_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(total_payment_value),
        2
    ) AS avg_payment_value

FROM vw_order_payment_profile

WHERE total_payment_value IS NOT NULL

GROUP BY payment_structure;





CREATE VIEW vw_payment_dashboard AS

SELECT
    order_id,
    customer_unique_id,

    purchase_year_month,
    customer_state,

    merchandise_gmv,
    freight_value,
    gross_order_value,

    total_payment_value,

    payment_record_count,
    payment_method_count,
    payment_methods,

    primary_payment_method,
    primary_payment_value,

    payment_structure,
    payment_difference

FROM vw_order_payment_profile;