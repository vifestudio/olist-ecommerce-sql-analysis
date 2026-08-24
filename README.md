# Olist Brazilian E-Commerce - SQL Analysis

![SQL](https://img.shields.io/badge/SQL-SQLite-blue)
![Python](https://img.shields.io/badge/Python-3.x-green)

## Overview
End to end data analysis of the Olist Brazilian E-Commerce dataset: 100k orders placed between 2016 and 2018. The project covers data ingestion, exploration, quality checks, cleaning, and business intelligence queries using SQL (SQLite) and Python.
---

## Dataset
Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) - Kaggle

9 tables / 7 entities:

| Table | Rows |
|---|---|
| customers | 99,441 |
| orders | 99,441 |
| order_items | 112,650 |
| payments | 103,886 |
| reviews | 99,224 |
| products | 32,951 |
| sellers | 3,095 |

![Row Counts](Screenshots/row_count.png)

---

## Data Model (Star Schema)

Built with dbt on top of the raw dataset.

```mermaid
erDiagram
    fct_orders {
        string order_id
        string customer_id FK
        string product_id FK
        string seller_id FK
        string date_id FK
        float  price
        float  freight_value
        float  total_amount
        int    delivery_days
    }
    dim_customers {
        string customer_id PK
        string customer_state
    }
    dim_products {
        string product_id PK
        string product_category_name
    }
    dim_sellers {
        string seller_id PK
        string seller_state
    }
    dim_dates {
        string date_id PK
        string year
        string month_name
        string quarter
    }

    fct_orders }o--|| dim_customers : "customer_id"
    fct_orders }o--|| dim_products  : "product_id"
    fct_orders }o--|| dim_sellers   : "seller_id"
    fct_orders }o--|| dim_dates     : "date_id"
```

---

## Schema (Raw Dataset)

```mermaid
erDiagram
    customers {
        string customer_id PK
        string customer_unique_id
        string customer_zip_code_prefix
        string customer_city
        string customer_state
    }
    orders {
        string order_id PK
        string customer_id FK
        string order_status
        string order_purchase_timestamp
        string order_approved_at
        string order_delivered_carrier_date
        string order_delivered_customer_date
        string order_estimated_delivery_date
    }
    order_items {
        string order_id FK
        int    order_item_id
        string product_id FK
        string seller_id FK
        string shipping_limit_date
        float  price
        float  freight_value
    }
    payments {
        string order_id FK
        int    payment_sequential
        string payment_type
        int    payment_installments
        float  payment_value
    }
    reviews {
        string review_id PK
        string order_id FK
        int    review_score
        string review_comment_title
        string review_comment_message
    }
    products {
        string product_id PK
        string product_category_name FK
        int    product_weight_g
        int    product_length_cm
        int    product_height_cm
        int    product_width_cm
    }
    sellers {
        string seller_id PK
        string seller_zip_code_prefix
        string seller_city
        string seller_state
    }
    categories {
        string product_category_name PK
        string product_category_name_english
    }

    customers   ||--o{ orders      : "places"
    orders      ||--|{ order_items : "contains"
    orders      ||--o{ payments    : "paid via"
    orders      ||--o{ reviews     : "reviewed in"
    products    ||--o{ order_items : "included in"
    sellers     ||--o{ order_items : "sells"
    categories  ||--o{ products    : "classifies"
```

---

## Project Structure

```
olist-ecommerce-sql-analysis/
├── data/                  # Raw CSVs (not tracked - see .gitignore)
├── queries/
│   └── ETL.sql            # Full pipeline: exploration, cleaning, analysis
├── schema/
│   └── ERD.md             # Entity relationship diagram
├── Screenshots/           # Query results
├── setup_db.py            # Loads CSVs into SQLite (olist.db)
└── README.md
```

---

## How to Run

**1. Download the dataset from Kaggle and place the CSVs in `data/`**

**2. Install dependencies**
```bash
pip install pandas
```

**3. Create the database**
```bash
python setup_db.py
```

**4. Open `queries/ETL.sql` in VS Code**
- Install the [SQLite extension](https://marketplace.visualstudio.com/items?itemName=alexcvzz.vscode-sqlite)
- `Ctrl+Shift+P` → SQLite: Open Database → select `olist.db`
- Run each query block individually

---

## Section 1 | Exploration & Quality Check

### Schema Inspection

PRAGMA queries confirm column names, data types, and structure across all 7 tables.

![PRAGMA customers](Screenshots/PRAGMA_customers.jpeg)
![PRAGMA orders](Screenshots/PRAGMA_orders.jpeg)
![PRAGMA order_items](Screenshots/PRAGMA_order%20Item.jpeg)
![PRAGMA payments](Screenshots/PRAGMA_payments.jpeg)
![PRAGMA reviews](Screenshots/PRAGMA_reviews.jpeg)
![PRAGMA products](Screenshots/PRAGMA_products.jpeg)
![PRAGMA sellers](Screenshots/PRAGMA_sellers.jpeg)

### Key Quality Findings

|     Table     |                 Issue                 |                   Decision                  |
|---------------|---------------------------------------|---------------------------------------------|
| orders        | 2,965 null delivery dates             | Filter `WHERE order_status = 'delivered'`   |
| orders        | 8 rows status='delivered' but no date | Exclude with `IS NOT NULL`                  |
| products      | 610 null categories                   | Replace with `'uncategorized'` via COALESCE |
| reviews       | 87,656 null comment titles            | Optional field - ignored in analysis        |
| customer_city | Typos and inconsistent formats        | Not used  `customer_state` used instead    |
| seller_city   | 22 rows with non-standard formats     | Not used in analysis                        |

---

## Section 2 - Data Cleaning

Two views created to address quality issues:

- **`products_clean`** - replaces NULL category with `'uncategorized'`
- **`sellers_clean`** (CTE) - assigns readable alias `Seller N` since seller names are anonymized UUIDs

---

## Section 3 - Analysis Queries

### Q1: Monthly Revenue Trend
How has revenue evolved month over month?

![Monthly Revenue Trend](Screenshots/monthly%20revenue%20trend.jpeg)

---

### Q2: Revenue by State
Which Brazilian states generate the most revenue?

![Revenue by State](Screenshots/revenue%20by%20state.jpeg)

---

### Q3: Top Categories by Revenue
Which product categories drive the most sales?

![Top Categories](Screenshots/top%20categories.jpeg)

---

### Q4: Top Sellers by Revenue
Who are the top 10 performing sellers?

![Top Sellers](Screenshots/top%20sellers.jpeg)

---

### Q5: Customer Satisfaction by Category
Which categories have the best and worst ratings?

![Customer Satisfaction](Screenshots/customer%20satisfaction%20.jpeg)

---

### Q6: Delivery Performance
Average delivery days by state and how proximity between seller and buyer impacts speed.

![Delivery Performance](Screenshots/delivery%20performance.jpeg)

**Same-state deliveries are consistently faster.** When seller and customer are in the same state, average delivery drops to 6–11 days. SP→SP alone accounts for 35,420 orders at 7.9 days average.

![Delivery by State Pair](Screenshots/relation%20between%20same%20state%20and%20delivery%20days.jpeg)

---

## Tools
- **SQLite** | database engine
- **Python + pandas** | CSV ingestion
- **VS Code** | SQL editor (SQLite extension)
- **dbt** | data transformation and star schema modeling
- **Power BI** | dashboard


