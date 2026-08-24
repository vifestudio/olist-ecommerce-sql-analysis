{{ config(materialized='view') }}

SELECT
    product_id,
    COALESCE(product_category_name, 'uncategorized') AS product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM {{ source('raw', 'products') }}
WHERE product_id IS NOT NULL
