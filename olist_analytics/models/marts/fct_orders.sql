{{ config(materialized='table') }}

SELECT
    oi.order_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,
    o.order_purchase_timestamp                              AS date_id,
    o.order_status,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value)                          AS total_amount,
    CAST(
        julianday(o.order_delivered_customer_date)
        - julianday(o.order_purchase_timestamp)
        AS INTEGER
    )                                                      AS delivery_days
FROM {{ ref('stg_orders') }} o
JOIN {{ source('raw', 'order_items') }} oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
