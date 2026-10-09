SELECT
    order_id,
    customer_unique_id,

    purchase_date,
    purchase_year_month,
    customer_state,

    merchandise_gmv,
    freight_value,
    item_count,
    distinct_seller_count,

    delivery_days,
    delay_days,
    is_delayed,

    review_score

FROM rpt_fact_order

WHERE order_status = 'delivered';