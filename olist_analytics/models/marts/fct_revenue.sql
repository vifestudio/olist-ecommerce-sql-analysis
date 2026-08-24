{{ config(materialized='table') }}

SELECT
    strftime('%Y-%m', o.order_purchase_timestamp)   AS month,
    c.customer_state                                 AS state,
    p.product_category_name                          AS category,
    COUNT(DISTINCT o.order_id)                       AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)       AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value), 2)       AS avg_ticket,
    ROUND(AVG(r.review_score), 2)                    AS avg_rating,
    ROUND(AVG(
        julianday(o.order_delivered_customer_date)
        - julianday(o.order_purchase_timestamp)
    ), 1)                                            AS avg_delivery_days
FROM {{ ref('stg_orders') }} o
JOIN {{ source('raw', 'order_items') }}  oi ON o.order_id    = oi.order_id
JOIN {{ source('raw', 'customers') }}    c  ON o.customer_id = c.customer_id
JOIN {{ ref('stg_products') }}           p  ON oi.product_id = p.product_id
LEFT JOIN {{ source('raw', 'reviews') }} r  ON o.order_id    = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY month, state, category
ORDER BY month, total_revenue DESC
