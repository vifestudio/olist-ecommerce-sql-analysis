-----------------------------------------------
--DATA EXPLORATION & QUALITY CHECK
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Author: Christian Mora Picado
-- Date: 2026-08-22
-----------------------------------------------

-- SECTION 1: EXPLORATION & QUALITY CHECK

-- SCHEMA INSPECTION
-- Run each line separately to inspect table structure
-------------------------------------------------------------
PRAGMA table_info(customers);
PRAGMA table_info(orders);
PRAGMA table_info(order_items);
PRAGMA table_info(payments);
PRAGMA table_info(reviews);
PRAGMA table_info(products);
PRAGMA table_info(sellers);



-- ROW COUNTS
-- Verify all tables loaded correctly
-------------------------------------------------------------
SELECT 'customers'   AS tbl, COUNT(*) AS rows FROM customers   UNION ALL
SELECT 'orders',             COUNT(*)          FROM orders      UNION ALL
SELECT 'order_items',        COUNT(*)          FROM order_items UNION ALL
SELECT 'payments',           COUNT(*)          FROM payments    UNION ALL
SELECT 'reviews',            COUNT(*)          FROM reviews     UNION ALL
SELECT 'products',           COUNT(*)          FROM products    UNION ALL
SELECT 'sellers',            COUNT(*)          FROM sellers;


-- SAMPLE DATA
-- Quick visual check of raw data per table
-- ------------------------------------------------------------
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;
SELECT * FROM products LIMIT 5;
SELECT * FROM payments LIMIT 5;
SELECT * FROM reviews LIMIT 5; 
SELECT * FROM customers LIMIT 5;
SELECT * FROM sellers LIMIT 5;



-- NULL CHECKS
-- Checking all key columns across tables
------------------------------------------------------------

-- Null check 
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)                        AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)                     AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END)                    AS null_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END)        AS null_purchase_date,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)               AS null_approved_at,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END)    AS null_carrier_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)   AS null_delivery_date,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END)   AS null_estimated_date
FROM orders;


-- RESULT: null_approved_at=160 | null_carrier_date=1783 | null_delivery_date=2965
-->  These are orders that were not fully delivered (cancelled, lost, in transit)
-->  Fix: filter with WHERE order_status = 'delivered' in all delivery time analysis


-- NULL CHECK: order_items
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)      AS null_order_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END)    AS null_product_id,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END)     AS null_seller_id,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END)         AS null_price,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS null_freight
FROM order_items;

-- NULL CHECK: payments
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)             AS null_order_id,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END)         AS null_payment_type,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END)        AS null_payment_value,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS null_installments
FROM payments;

-- NULL CHECK: reviews
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)             AS null_order_id,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END)         AS null_score,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END)   AS null_title,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_message
FROM reviews;

-- NULL CHECK: products
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END)            AS null_product_id,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END)      AS null_weight
FROM products;


-- NULL CHECK RESULTS SUMMARY
-------------------------------------------------------------
-- orders:
--   null_approved_at      = 160   → orders never approved
--   null_carrier_date     = 1,783 → orders never shipped
--   null_delivery_date    = 2,965 → orders never delivered
--   Fix: WHERE order_status = 'delivered' in delivery time analysis

-- Verify why delivery dates are null
SELECT 
    order_status,
    COUNT(*) AS total
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY total DESC;

-- orders: null_delivery_date = 2,965
--   2,957 → legitimate: orders not yet delivered (shipped, cancelled, unavailable, etc.)
--   8     → data quality issue: status = 'delivered' but delivery date is missing
--   Fix: WHERE order_status = 'delivered' 
--         AND order_delivered_customer_date IS NOT NULL
---------------------------------------------------------------
-- reviews:
--   null_comment_title    = 87,656 → optional field by design
--   null_comment_message  = 58,247 → optional field by design
--   Fix: use only review_score, ignore comment columns
--
-- products:
--   null_category         = 610   → products with no category assigned
--   null_weight           = 2     → not used in analysis
--   Fix: COALESCE(product_category_name, 'uncategorized')
--
-- order_items, payments, customers, sellers: ✓ no nulls found
----------------------------------------------------------------





-- DATE FORMAT CHECK
-------------------------------------------------------------
-- Check for inconsistent date formats across all rows
-- Detect date format variants
SELECT
    CASE
        WHEN order_purchase_timestamp LIKE '____-__-__ __:__:__' THEN 'YYYY-MM-DD HH:MM:SS'
        WHEN order_purchase_timestamp LIKE '__/__/____ __:__:__' THEN 'MM/DD/YYYY HH:MM:SS'
        WHEN order_purchase_timestamp LIKE '__-__-____ __:__:__' THEN 'DD-MM-YYYY HH:MM:SS'
        ELSE 'unknown format'
    END AS date_format,
    COUNT(*) AS total
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY date_format;

-- TEXT QUALITY CHECK
-------------------------------------------------------------
-- Check for inconsistencies in categorical text columns

-- Product categories
SELECT 
    product_category_name,
    LOWER(product_category_name) AS normalized,
    COUNT(*) AS total
FROM products
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY normalized;


-- Customer cities
SELECT 
    customer_city,
    LOWER(customer_city) AS normalized,
    COUNT(*) AS total
FROM customers
GROUP BY customer_city
ORDER BY normalized
LIMIT 30;

-- Customer states
SELECT DISTINCT customer_state 
FROM customers 
ORDER BY customer_state;

-- Seller cities
SELECT 
    seller_city,
    LOWER(seller_city) AS normalized,
    COUNT(*) AS total
FROM sellers
GROUP BY seller_city
ORDER BY normalized;


-- customer_city: inconsistent formats and typos found during visual inspection
-- Examples: 'balenario camboriu', 'mogi das cruses', 'sao paulop', 'ribeirao pretp'
-- Decision: customer_city NOT used in analysis → no cleaning applied
-- Analysis will use customer_state (2-letter code, clean and consistent)





-- Duplicate check on primary keys
-- Note: order_items and payments excluded — multiple rows per order_id is by design
SELECT 'orders' AS tbl, order_id AS id, COUNT(*) AS total
FROM orders GROUP BY order_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'customers', customer_id, COUNT(*)
FROM customers GROUP BY customer_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'products', product_id, COUNT(*)
FROM products GROUP BY product_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'sellers', seller_id, COUNT(*)
FROM sellers GROUP BY seller_id HAVING COUNT(*) > 1;


-- Duplicate check on primary keys
 -- RESULT: No duplicate primary keys found in orders, customers, products or sellers
-- → Referential integrity is clean


-- JOIN integrity check
SELECT
    COUNT(DISTINCT o.order_id)                    AS total_orders,
    COUNT(DISTINCT oi.order_id)                   AS orders_with_items,
    COUNT(DISTINCT p.order_id)                    AS orders_with_payments,
    COUNT(DISTINCT r.order_id)                    AS orders_with_reviews
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN payments p    ON o.order_id = p.order_id
LEFT JOIN reviews r     ON o.order_id = r.order_id;

-- JOIN INTEGRITY CHECK RESULTS
-- total_orders        = 99,441
-- orders_with_items   = 98,666 → 775 orders with no items (likely cancelled before processing)
-- orders_with_payments= 99,440 → 1 order with no payment record
-- orders_with_reviews = 98,673 → 768 orders with no review (optional by design)
-- → All JOINs are valid, no referential integrity issues


-- 
-- SECTION 2: DATA CLEANING
-----------------------------------------------------------------------------

-- FIX 1: Assign 'uncategorized' to products with no category
-- 610 products had NULL in product_category_name
-- VIEW: products with cleaned category
CREATE VIEW IF NOT EXISTS products_clean AS
SELECT 
    product_id,
    COALESCE(product_category_name, 'uncategorized') AS product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products;


-- Verify view works correctly
SELECT COUNT(*) AS nulls_in_view 
FROM products_clean 
WHERE product_category_name = 'uncategorized';
-- Expected: 610

-- NOTE: sellers_clean not created as a VIEW
-- ROW_NUMBER() OVER (...) in VIEW definitions is unsupported by the SQLite VS Code extension
-- seller_name alias is generated inline via CTE in Q4 instead

-- FIX 2: seller_city inconsistent formats — NOT applied
-- 22 rows with formats like 'sao paulo - sp', 'rio de janeiro / rio de janeiro'
-- Decision: seller_city not used in analysis → no cleaning applied


-- FIX 3: customer_city typos — NOT applied  
-- Decision: customer_city not used in analysis → customer_state used instead


-- NOTE: orders with null delivery dates handled at query level
-- Filter applied in all delivery analysis: 
-- WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL



-- SECTION 3: ANALYSIS QUERIES
-- Business questions answered with clean, production-ready SQL
-------------------------------------------------------------


-- Q1: TOTAL REVENUE & MONTHLY TREND
-- How has revenue evolved over time?
-------------------------------------------------------------
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id)                     AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)     AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value), 2)     AS avg_ticket
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- Q2: REVENUE BY STATE
-- Which Brazilian states generate the most revenue?
-------------------------------------------------------------
SELECT
    c.customer_state                               AS state,
    COUNT(DISTINCT o.order_id)                     AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)     AS total_revenue
FROM orders o
JOIN order_items oi  ON o.order_id  = oi.order_id
JOIN customers c     ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY state
ORDER BY total_revenue DESC;


-- Q3: TOP CATEGORIES BY REVENUE
-- Which product categories drive the most sales?
-------------------------------------------------------------
SELECT
    COALESCE(p.product_category_name, 'uncategorized') AS category,
    COUNT(DISTINCT oi.order_id)                         AS total_orders,
    ROUND(SUM(oi.price), 2)                             AS total_revenue,
    ROUND(AVG(oi.price), 2)                             AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 15;


-- Q4: TOP SELLERS BY REVENUE
-- Who are the best performing sellers?
-------------------------------------------------------------
WITH sellers_clean AS (
    SELECT
        seller_id,
        'Seller ' || ROW_NUMBER() OVER (ORDER BY seller_id) AS seller_name,
        seller_state
    FROM sellers
)
SELECT
    sc.seller_name,
    sc.seller_state,
    COUNT(DISTINCT oi.order_id)                AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value), 2) AS avg_ticket
FROM order_items oi
JOIN orders o        ON oi.order_id  = o.order_id
JOIN sellers_clean sc ON oi.seller_id = sc.seller_id
WHERE o.order_status = 'delivered'
GROUP BY sc.seller_name
ORDER BY total_revenue DESC
LIMIT 10;


-- Q5: CUSTOMER SATISFACTION BY CATEGORY
-- Which categories have the best and worst ratings?
-------------------------------------------------------------
SELECT
    COALESCE(p.product_category_name, 'uncategorized') AS category,
    ROUND(AVG(r.review_score), 2)                       AS avg_rating,
    COUNT(r.review_id)                                  AS total_reviews
FROM reviews r
JOIN orders o       ON r.order_id    = o.order_id
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
GROUP BY category
HAVING total_reviews >= 50
ORDER BY avg_rating DESC
LIMIT 15;


-- Q6: DELIVERY PERFORMANCE
-- How many days on average does delivery take?
-------------------------------------------------------------
SELECT
    c.customer_state                                              AS state,
    ROUND(AVG(julianday(o.order_delivered_customer_date)
            - julianday(o.order_purchase_timestamp)), 1)         AS avg_delivery_days,
    ROUND(AVG(julianday(o.order_estimated_delivery_date)
            - julianday(o.order_purchase_timestamp)), 1)         AS avg_estimated_days,
    COUNT(DISTINCT o.order_id)                                   AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY state
ORDER BY avg_delivery_days DESC;

-- Delivery days vs distance proxy (seller state vs customer state)
SELECT
    s.seller_state,
    c.customer_state,
    ROUND(AVG(julianday(o.order_delivered_customer_date)
            - julianday(o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    COUNT(*) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c    ON o.customer_id = c.customer_id
JOIN sellers s      ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_state, c.customer_state
HAVING total_orders >= 50
ORDER BY avg_delivery_days ASC
LIMIT 15;