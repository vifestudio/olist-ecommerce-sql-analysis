import sqlite3
import pandas as pd
from pathlib import Path

DB_PATH = Path(__file__).parent / "olist.db"
DATA_DIR = Path(__file__).parent / "data"

TABLES = {
    "customers":    "olist_customers_dataset.csv",
    "geolocation":  "olist_geolocation_dataset.csv",
    "orders":       "olist_orders_dataset.csv",
    "order_items":  "olist_order_items_dataset.csv",
    "payments":     "olist_order_payments_dataset.csv",
    "reviews":      "olist_order_reviews_dataset.csv",
    "products":     "olist_products_dataset.csv",
    "sellers":      "olist_sellers_dataset.csv",
    "categories":   "product_category_name_translation.csv",
}

conn = sqlite3.connect(DB_PATH)

for table, filename in TABLES.items():
    filepath = DATA_DIR / filename
    df = pd.read_csv(filepath)
    df.to_sql(table, conn, if_exists="replace", index=False)
    print(f"  {table:15s} → {len(df):,} rows")

conn.close()
print(f"\nDone. Database saved to: {DB_PATH}")