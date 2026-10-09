-- =========================================================
-- 14 Geographic Intelligence
-- ---------------------------------------------------------
-- Purpose:
-- Analyze regional demand, seller supply, fulfillment
-- performance and customer experience while building
-- a safe geographic dimension from raw geolocation data.
-- =========================================================
CREATE VIEW vw_geolocation_dedup AS

SELECT DISTINCT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng

FROM geolocations

WHERE geolocation_lat BETWEEN -90 AND 90
  AND geolocation_lng BETWEEN -180 AND 180;




CREATE VIEW vw_geo_zip_centroid AS

SELECT
    geolocation_zip_code_prefix,

    AVG(geolocation_lat)
        AS latitude,

    AVG(geolocation_lng)
        AS longitude,

    COUNT(*) AS coordinate_samples

FROM vw_geolocation_dedup

GROUP BY geolocation_zip_code_prefix;




CREATE VIEW vw_order_geography AS

SELECT
    f.order_id,
    f.customer_unique_id,

    f.customer_zip_code_prefix,
    f.customer_city,
    f.customer_state,

    g.latitude AS customer_latitude,
    g.longitude AS customer_longitude,

    f.purchase_year_month,

    f.merchandise_gmv,
    f.freight_value,
    f.gross_order_value,

    f.item_count,

    f.delivery_days,
    f.delay_days,
    f.is_delayed,

    r.review_score,

    'Brazil' AS country

FROM vw_order_fact f

LEFT JOIN vw_geo_zip_centroid g
    ON f.customer_zip_code_prefix =
       g.geolocation_zip_code_prefix

LEFT JOIN vw_order_review_latest r
    ON f.order_id = r.order_id

WHERE f.order_status = 'delivered';




CREATE VIEW vw_state_performance AS

WITH state_base AS (

    SELECT
        customer_state,

        COUNT(DISTINCT order_id)
            AS orders,

        COUNT(DISTINCT customer_unique_id)
            AS customers,

        ROUND(
            SUM(merchandise_gmv),
            2
        ) AS merchandise_gmv,

        ROUND(
            SUM(freight_value),
            2
        ) AS freight_value,

        ROUND(
            SUM(gross_order_value),
            2
        ) AS gross_order_value,

        ROUND(
            SUM(merchandise_gmv)
            / NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS aov,

        ROUND(
            SUM(freight_value)
            / NULLIF(COUNT(DISTINCT order_id), 0),
            2
        ) AS freight_per_order,

        ROUND(
            SUM(freight_value) * 100.0
            / NULLIF(SUM(merchandise_gmv), 0),
            2
        ) AS freight_to_gmv_pct,

        ROUND(
            AVG(delivery_days),
            2
        ) AS avg_delivery_days,

        ROUND(
            AVG(delay_days),
            2
        ) AS avg_delay_days,

        ROUND(
            AVG(is_delayed) * 100,
            2
        ) AS delay_rate,

        ROUND(
            AVG(review_score),
            2
        ) AS avg_review_score,

        ROUND(
            AVG(
                CASE
                    WHEN review_score <= 2 THEN 1
                    WHEN review_score IS NOT NULL THEN 0
                END
            ) * 100,
            2
        ) AS low_rating_rate

    FROM vw_order_geography

    WHERE customer_state IS NOT NULL

    GROUP BY customer_state
)

SELECT
    *,

    ROUND(
        merchandise_gmv * 100.0
        / SUM(merchandise_gmv) OVER (),
        2
    ) AS gmv_share_pct

FROM state_base;

WITH ranked AS (

    SELECT
        customer_state,
        merchandise_gmv,

        ROW_NUMBER() OVER (
            ORDER BY merchandise_gmv DESC
        ) AS rn

    FROM vw_state_performance
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
    ) AS top5_state_gmv_share

FROM ranked;



SELECT
    customer_state,
    orders,
    customers,
    merchandise_gmv,
    aov
FROM vw_state_performance
WHERE orders >= 100
ORDER BY aov DESC;




SELECT
    customer_state,

    orders,
    merchandise_gmv,

    freight_per_order,
    freight_to_gmv_pct,

    avg_delivery_days,
    delay_rate

FROM vw_state_performance

WHERE orders >= 100

ORDER BY freight_to_gmv_pct DESC;



SELECT
    customer_state,

    orders,

    avg_delivery_days,
    avg_delay_days,
    delay_rate

FROM vw_state_performance

WHERE orders >= 100

ORDER BY avg_delivery_days DESC;




SELECT
    customer_state,

    orders,

    avg_review_score,
    low_rating_rate,

    avg_delivery_days,
    delay_rate

FROM vw_state_performance

WHERE orders >= 100

ORDER BY low_rating_rate DESC;





CREATE VIEW vw_state_ranked AS

SELECT
    *,

    PERCENT_RANK() OVER (
        ORDER BY merchandise_gmv
    ) AS gmv_percentile,

    PERCENT_RANK() OVER (
        ORDER BY delay_rate
    ) AS delay_percentile

FROM vw_state_performance

WHERE orders >= 100;




SELECT
    customer_state,
    orders,
    merchandise_gmv,
    avg_delivery_days,
    delay_rate,
    avg_review_score,

    CASE

        WHEN gmv_percentile >= 0.50
         AND delay_percentile < 0.50
        THEN 'Core Efficient Market'

        WHEN gmv_percentile >= 0.50
         AND delay_percentile >= 0.50
        THEN 'High-Value Operational Risk'

        WHEN gmv_percentile < 0.50
         AND delay_percentile < 0.50
        THEN 'Efficient Growth Market'

        ELSE 'Low-Scale / Fulfillment Challenge'

    END AS regional_position

FROM vw_state_ranked

ORDER BY merchandise_gmv DESC;





CREATE VIEW vw_seller_state_supply AS

WITH state_supply AS (

    SELECT
        os.seller_state,

        COUNT(DISTINCT os.seller_id)
            AS sellers,

        COUNT(*) AS seller_order_links,

        COUNT(DISTINCT os.customer_unique_id)
            AS customers_served,

        COUNT(DISTINCT f.customer_state)
            AS destination_states,

        SUM(os.units_sold)
            AS units_sold,

        ROUND(
            SUM(os.seller_merchandise_gmv),
            2
        ) AS seller_origin_gmv

    FROM vw_order_seller os

    INNER JOIN vw_order_fact f
        ON os.order_id = f.order_id

    WHERE os.order_status = 'delivered'
      AND os.seller_state IS NOT NULL

    GROUP BY os.seller_state
)

SELECT
    *,

    ROUND(
        seller_origin_gmv * 100.0
        / SUM(seller_origin_gmv) OVER (),
        2
    ) AS seller_gmv_share_pct

FROM state_supply;





CREATE VIEW vw_state_market_dashboard AS

SELECT
    states.state_code,

    d.orders AS customer_orders,
    d.customers,
    d.merchandise_gmv AS customer_demand_gmv,
    d.gmv_share_pct AS demand_gmv_share_pct,
    d.aov,

    d.freight_per_order,
    d.freight_to_gmv_pct,

    d.avg_delivery_days,
    d.delay_rate,
    d.avg_review_score,
    d.low_rating_rate,

    s.sellers,
    s.seller_origin_gmv,
    s.seller_gmv_share_pct AS supply_gmv_share_pct,
    s.destination_states,

    ROUND(
        COALESCE(s.seller_gmv_share_pct, 0)
        -
        COALESCE(d.gmv_share_pct, 0),
        2
    ) AS supply_demand_share_gap_pp,

    'Brazil' AS country

FROM (

    SELECT customer_state AS state_code
    FROM vw_state_performance

    UNION

    SELECT seller_state AS state_code
    FROM vw_seller_state_supply

) states

LEFT JOIN vw_state_performance d
    ON states.state_code =
       d.customer_state

LEFT JOIN vw_seller_state_supply s
    ON states.state_code =
       s.seller_state;



SELECT
    state_code,

    customer_demand_gmv,
    demand_gmv_share_pct,

    sellers,
    seller_origin_gmv,
    supply_gmv_share_pct,

    supply_demand_share_gap_pp

FROM vw_state_market_dashboard

ORDER BY customer_demand_gmv DESC;




SELECT
    state_code,

    customer_demand_gmv,
    demand_gmv_share_pct,

    sellers,
    seller_origin_gmv,
    supply_gmv_share_pct,

    supply_demand_share_gap_pp

FROM vw_state_market_dashboard

ORDER BY customer_demand_gmv DESC;





CREATE VIEW vw_state_trade_flow AS

SELECT
    os.seller_state AS origin_state,
    f.customer_state AS destination_state,

    COUNT(*) AS seller_order_links,

    COUNT(DISTINCT os.seller_id)
        AS sellers,

    COUNT(DISTINCT os.customer_unique_id)
        AS customers,

    ROUND(
        SUM(os.seller_merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(os.seller_freight_value),
        2
    ) AS freight_value

FROM vw_order_seller os

INNER JOIN vw_order_fact f
    ON os.order_id = f.order_id

WHERE os.order_status = 'delivered'
  AND os.seller_state IS NOT NULL
  AND f.customer_state IS NOT NULL

GROUP BY
    os.seller_state,
    f.customer_state;







CREATE VIEW vw_single_seller_order_distance AS

SELECT
    os.order_id,
    os.seller_id,
    f.customer_unique_id,

    os.seller_state,
    f.customer_state,

    s.seller_zip_code_prefix,
    f.customer_zip_code_prefix,

    sg.latitude AS seller_latitude,
    sg.longitude AS seller_longitude,

    cg.latitude AS customer_latitude,
    cg.longitude AS customer_longitude,

    ROUND(
        ST_Distance_Sphere(
            POINT(
                sg.longitude,
                sg.latitude
            ),
            POINT(
                cg.longitude,
                cg.latitude
            )
        ) / 1000,
        2
    ) AS straight_line_distance_km,

    os.seller_merchandise_gmv
        AS merchandise_gmv,

    os.seller_freight_value
        AS freight_value,

    f.delivery_days,
    f.delay_days,
    f.is_delayed,

    r.review_score,

    CASE
        WHEN os.seller_state = f.customer_state
        THEN 'Same State'
        ELSE 'Cross State'
    END AS geographic_relation

FROM vw_order_seller os

INNER JOIN vw_order_fact f
    ON os.order_id = f.order_id

INNER JOIN sellers s
    ON os.seller_id = s.seller_id

LEFT JOIN vw_geo_zip_centroid sg
    ON s.seller_zip_code_prefix =
       sg.geolocation_zip_code_prefix

LEFT JOIN vw_geo_zip_centroid cg
    ON f.customer_zip_code_prefix =
       cg.geolocation_zip_code_prefix

LEFT JOIN vw_order_review_latest r
    ON os.order_id = r.order_id

WHERE os.order_status = 'delivered'
  AND f.distinct_seller_count = 1
  AND sg.latitude IS NOT NULL
  AND sg.longitude IS NOT NULL
  AND cg.latitude IS NOT NULL
  AND cg.longitude IS NOT NULL;



SELECT
    COUNT(*) AS eligible_orders,

    ROUND(
        MIN(straight_line_distance_km),
        2
    ) AS min_distance_km,

    ROUND(
        AVG(straight_line_distance_km),
        2
    ) AS avg_distance_km,

    ROUND(
        MAX(straight_line_distance_km),
        2
    ) AS max_distance_km

FROM vw_single_seller_order_distance;




SELECT
    CASE
        WHEN straight_line_distance_km < 100
        THEN '<100 km'

        WHEN straight_line_distance_km < 500
        THEN '100-499 km'

        WHEN straight_line_distance_km < 1000
        THEN '500-999 km'

        WHEN straight_line_distance_km < 2000
        THEN '1000-1999 km'

        ELSE '2000+ km'
    END AS distance_band,

    COUNT(*) AS orders,

    ROUND(
        AVG(straight_line_distance_km),
        2
    ) AS avg_distance_km,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(is_delayed) * 100,
        2
    ) AS delay_rate,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score

FROM vw_single_seller_order_distance

GROUP BY
    CASE
        WHEN straight_line_distance_km < 100 THEN '<100 km'
        WHEN straight_line_distance_km < 500 THEN '100-499 km'
        WHEN straight_line_distance_km < 1000 THEN '500-999 km'
        WHEN straight_line_distance_km < 2000 THEN '1000-1999 km'
        ELSE '2000+ km'
    END

ORDER BY MIN(straight_line_distance_km);




SELECT
    geographic_relation,

    COUNT(*) AS orders,

    ROUND(
        AVG(straight_line_distance_km),
        2
    ) AS avg_distance_km,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(is_delayed) * 100,
        2
    ) AS delay_rate,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score

FROM vw_single_seller_order_distance

GROUP BY geographic_relation;




SELECT
    geographic_relation,

    ROUND(
        SUM(freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(freight_value) * 100.0
        / NULLIF(SUM(merchandise_gmv), 0),
        2
    ) AS freight_to_gmv_pct

FROM vw_single_seller_order_distance

GROUP BY geographic_relation;




SELECT
    geographic_relation,

    ROUND(
        SUM(freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(merchandise_gmv),
        2
    ) AS merchandise_gmv,

    ROUND(
        SUM(freight_value) * 100.0
        / NULLIF(SUM(merchandise_gmv), 0),
        2
    ) AS freight_to_gmv_pct

FROM vw_single_seller_order_distance

GROUP BY geographic_relation;






CREATE VIEW vw_distance_dashboard AS

SELECT
    *,

    CASE
        WHEN straight_line_distance_km < 100
        THEN '<100 km'

        WHEN straight_line_distance_km < 500
        THEN '100-499 km'

        WHEN straight_line_distance_km < 1000
        THEN '500-999 km'

        WHEN straight_line_distance_km < 2000
        THEN '1000-1999 km'

        ELSE '2000+ km'
    END AS distance_band

FROM vw_single_seller_order_distance;