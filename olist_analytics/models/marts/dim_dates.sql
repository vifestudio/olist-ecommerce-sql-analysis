{{ config(materialized='table') }}

SELECT DISTINCT
    order_purchase_timestamp                                    AS date_id,
    strftime('%Y-%m-%d', order_purchase_timestamp)             AS date,
    strftime('%Y', order_purchase_timestamp)                   AS year,
    strftime('%m', order_purchase_timestamp)                   AS month_num,
    strftime('%Y-%m', order_purchase_timestamp)                AS year_month,
    CASE strftime('%m', order_purchase_timestamp)
        WHEN '01' THEN 'January'   WHEN '02' THEN 'February'
        WHEN '03' THEN 'March'     WHEN '04' THEN 'April'
        WHEN '05' THEN 'May'       WHEN '06' THEN 'June'
        WHEN '07' THEN 'July'      WHEN '08' THEN 'August'
        WHEN '09' THEN 'September' WHEN '10' THEN 'October'
        WHEN '11' THEN 'November'  WHEN '12' THEN 'December'
    END                                                        AS month_name,
    CASE CAST(strftime('%m', order_purchase_timestamp) AS INTEGER)
        WHEN 1 THEN 'Q1' WHEN 2 THEN 'Q1' WHEN 3 THEN 'Q1'
        WHEN 4 THEN 'Q2' WHEN 5 THEN 'Q2' WHEN 6 THEN 'Q2'
        WHEN 7 THEN 'Q3' WHEN 8 THEN 'Q3' WHEN 9 THEN 'Q3'
        ELSE 'Q4'
    END                                                        AS quarter,
    strftime('%w', order_purchase_timestamp)                   AS day_of_week
FROM {{ ref('stg_orders') }}
WHERE order_purchase_timestamp IS NOT NULL