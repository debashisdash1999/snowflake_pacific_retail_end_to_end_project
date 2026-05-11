# PacificRetail: End-to-End Snowflake Data Engineering Project

## Project Overview

PacificRetail is a large-scale e-commerce company operating across **15 countries in North America and Europe**, with over **5 million active customers** and **100,000+ products** in its catalog.

### The Problem

The business was running into a set of interconnected data challenges:

- **Data silos** — Customer, product, and transaction data lived in separate systems with no unified view across them
- **Reporting lag** — Batch processing introduced a 24-hour delay in sales and analytics reporting
- **Scalability bottlenecks** — The on-premises warehouse struggled to keep up during peak sales periods
- **Data quality issues** — Inconsistencies across sources made it difficult to trust the data
- **Limited analytics** — The existing setup couldn't support the advanced analytics and ML use cases the business needed

### The Goal

Build a modern, cloud-native data engineering solution on Snowflake that:

- Centralizes data from all sources into a single platform
- Brings reporting latency down from 24 hours to under 1 hour
- Scales to handle 5x the current data volume
- Improves data quality and consistency end-to-end
- Enables self-service analytics and lays the groundwork for ML models

---

## Data Sources

| Source | Format | Volume |
|---|---|---|
| Customer Data (CRM) | CSV (daily) | ~100K records/day |
| Product Catalog (Inventory) | JSON (hourly) | ~10K changes/day |
| Transaction Logs (E-commerce) | Parquet (real-time) | ~500K transactions/day |

---

## Architecture Overview

The pipeline follows a **three-layer Medallion Architecture**: Bronze (raw ingestion) → Silver (cleansed and conformed) → Gold (business-level aggregates).

```
Source Systems → Azure Data Lake Storage (ADLS) → Bronze → Silver → Gold → BI Tools
```

### Layer Breakdown

**Bronze — Raw Ingestion**
Data lands here exactly as received from source systems. No transformations, no schema changes. The goal is to preserve the original structure for traceability and reprocessing.

**Silver — Cleansed and Conformed**
This is where the heavy lifting happens. Data goes through validation, standardization, and CDC (Change Data Capture) using Snowflake MERGE statements. Key checks include:

- **Customer**: Email not null, age between 18-120, customer type normalized to `regular` / `premium` / `unknown`, gender standardized, purchase counts defaulted to 0 if invalid
- **Product**: Price must be positive, stock non-negative, rating between 0 and 5

Business logic and validation are handled via **Stored Procedures and Tasks**, keeping transformation logic modular and auditable.

**Gold — Business Aggregates**
Denormalized, query-optimized views designed for BI consumption. Built for speed and self-service analytics.

---

## Gold Layer Views

### Daily Sales Analysis

Aggregates sales by day, product, and customer type — supports revenue tracking, pricing analysis, and transaction volume reporting.

```sql
CREATE OR REPLACE VIEW VW_DAILY_SALES_ANALYSIS AS
SELECT 
    o.transaction_date,
    p.product_id,
    p.name AS product_name,
    p.category AS product_category,
    c.customer_id,
    c.customer_type,
    SUM(o.quantity) AS total_quantity,
    SUM(o.total_amount) AS total_sales,
    COUNT(DISTINCT o.transaction_id) AS num_transactions,
    SUM(o.total_amount) / NULLIF(SUM(o.quantity), 0) AS avg_price_per_unit,
    SUM(o.total_amount) / NULLIF(COUNT(DISTINCT o.transaction_id), 0) AS avg_transaction_value
FROM SILVER.ORDERS o
JOIN SILVER.PRODUCT p ON o.product_id = p.product_id
JOIN SILVER.CUSTOMER c ON o.customer_id = c.customer_id
GROUP BY 
    o.transaction_date, p.product_id, p.name, p.category, c.customer_id, c.customer_type;
```

### Customer Product Affinity

Tracks purchasing behavior at the customer-product level over time — useful for segmentation, recommendation models, and churn analysis.

```sql
CREATE OR REPLACE VIEW VW_CUSTOMER_PRODUCT_AFFINITY AS
SELECT 
    c.customer_id,
    c.customer_type,
    p.product_id,
    p.name AS product_name,
    p.category AS product_category,
    DATE_TRUNC('MONTH', o.transaction_date) AS purchase_month,
    COUNT(DISTINCT o.transaction_id) AS purchase_count,
    SUM(o.quantity) AS total_quantity,
    SUM(o.total_amount) AS total_spent,
    AVG(o.total_amount) AS avg_purchase_amount,
    DATEDIFF('DAY', MIN(o.transaction_date), MAX(o.transaction_date)) AS days_between_first_last_purchase
FROM SILVER.CUSTOMER c
JOIN SILVER.ORDERS o ON c.customer_id = o.customer_id
JOIN SILVER.PRODUCT p ON o.product_id = p.product_id
GROUP BY 
    c.customer_id, c.customer_type, p.product_id, p.name, p.category, DATE_TRUNC('MONTH', o.transaction_date);
```

---

## Key Snowflake Features Used

| Feature | Purpose |
|---|---|
| External Stages | Connect Snowflake to ADLS for file ingestion |
| COPY Command | Bulk load raw files into Bronze tables |
| Streams | Track incremental changes for CDC |
| Tasks | Schedule and automate pipeline execution |
| Stored Procedures | Encapsulate transformation and validation logic |
| Time Travel | Recover deleted or modified data; review historical state |
| Zero-Copy Cloning | Create dev/test environments without duplicating storage |

---

## Key Components

- Snowflake Database with Bronze, Silver, and Gold schemas
- External Stage connected to Azure Data Lake Storage
- Automated ELT pipeline using Tasks, Streams, and Stored Procedures
- Gold layer views ready for BI consumption

---

## Reporting and Analytics

Gold layer views connect directly to BI tools including **Power BI**, **Tableau**, and **Looker**.

Dashboards built on this architecture can support:

- Sales performance tracking by product, region, and customer segment
- Customer behavior analysis and segmentation
- Product performance and inventory insights

---

## Outcomes

| Metric | Before | After |
|---|---|---|
| Data processing time | 24 hours | < 1 hour |
| Reporting accuracy | Inconsistent | 99.9% target across channels |
| Data volume capacity | Current load | Designed for 5x growth |
| Analytics access | Engineering-dependent | Self-service ready |
