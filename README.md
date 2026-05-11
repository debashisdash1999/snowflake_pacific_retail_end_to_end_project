# PacificRetail: End-to-End Snowflake Data Engineering Project

> Follow the code files chronologically alongside this README to understand the full project workflow.

---

## Project Overview

PacificRetail is a large-scale e-commerce company operating across **15 countries in North America and Europe**, with over **5 million active customers** and **100,000+ products** in its catalog.

### Challenges

The business was dealing with several interconnected data problems:

- **Data silos** — Customer, product, and transaction data were stored in separate systems with no unified view across them
- **Processing delays** — Batch processing caused a 24-hour lag in sales and analytics reporting
- **Scalability issues** — The on-premises warehouse struggled to keep up during peak sales periods
- **Data quality inconsistencies** — Mismatches and invalid records across sources made the data unreliable
- **Limited analytics capabilities** — The existing setup couldn't support the advanced analytics and ML use cases the business needed

### Goals

Implement a modern data engineering solution on Snowflake to:

- Centralize all data from disparate sources into a single platform
- Reduce reporting latency from 24 hours to under 1 hour
- Improve data quality and consistency end-to-end
- Scale to handle 5x the current data volume
- Enable self-service analytics
- Provide a solid foundation for ML models

---

## Data Sources

| Source | Format | Volume |
|---|---|---|
| Customer Data (CRM) | CSV — daily | ~100K records/day |
| Product Catalog (Inventory System) | JSON — hourly | ~10K changes/day |
| Transaction Logs (E-commerce Platform) | Parquet — real-time | ~500K transactions/day |

---

## Expected Outcomes

- Reduce data processing time from **24 hours to under 1 hour**
- Achieve **99.9% accuracy** in cross-channel reporting
- Scale to handle **5x current data volume**
- Enable **self-service analytics** for business users
- Provide a foundation for building **ML models** on top of clean, structured data

---

## Architecture Overview

The pipeline follows a **three-layer Medallion Architecture**: Bronze (raw ingestion) → Silver (cleansed and conformed) → Gold (business-level aggregates).

### High-Level Components

1. **Data Sources**
   - CRM → Customer data
   - Inventory System → Product catalog
   - E-commerce Platform → Transaction data

2. **Azure Data Lake Storage (ADLS)**
   - Acts as the centralized staging area before Snowflake ingestion
   - Stores raw files in CSV, JSON, and Parquet formats

3. **Snowflake Data Warehouse**
   - Connects to ADLS via External Stages
   - Ingests data using the COPY command
   - Organizes data across Bronze, Silver, and Gold schemas
   - Provides scalable compute for analytics

4. **Data Processing Layers**

   **Bronze — Raw Ingestion**
   Data lands here exactly as received. No transformations are applied — the original structure is preserved for traceability and reprocessing.

   **Silver — Cleansed and Conformed**
   Data is validated, standardized, and deduplicated here. CDC (Change Data Capture) is implemented using Snowflake MERGE statements. Business logic and validation are handled via Stored Procedures and Tasks.

   **Gold — Business Aggregates**
   Denormalized, query-optimized views built for BI tools and self-service analytics.

---

## Data Flow

```
Source Systems → ADLS → Bronze Layer → Silver Layer → Gold Layer → BI Tools
```

---

## Transformations & Validations

### Customer Table
- Email must not be null
- Customer type normalized to `regular`, `premium`, or `unknown`
- Age must fall between 18 and 120
- Gender standardized to `male`, `female`, or `other`
- Total purchases validated as numeric; defaults to 0 if invalid

### Product Table
- Price must be a positive number
- Stock quantity must be non-negative
- Rating must fall between 0 and 5

**Implementation:** Validation and transformation logic is encapsulated in Stored Procedures, with Tasks handling scheduled execution and automation across pipeline stages.

---

## Gold Layer Views

### 1. Daily Sales Analysis

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

### 2. Customer Product Affinity

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
| Zero-Copy Cloning | Spin up dev/test environments without duplicating storage |

---

## Benefits of this Architecture

- **Scalability** — Designed to handle current workloads and scale to 5x projected data growth without architectural changes
- **Flexibility** — Works across diverse data formats (CSV, JSON, Parquet) and multiple source systems
- **Performance** — Processing time reduced from 24 hours to under 1 hour through automated, layered pipelines
- **Cost Efficiency** — Snowflake's separation of compute and storage keeps costs proportional to actual usage
- **Data Governance** — Layered validation, CDC, and Time Travel provide strong auditability and data quality controls

---

## Key Components

- Snowflake Database with Bronze, Silver, and Gold schemas
- External Stage connected to Azure Data Lake Storage
- Tables, Streams, Tasks, and Stored Procedures for automated ELT
- Gold Layer Views optimized for BI consumption

---

## Reporting & Analytics

Gold layer views connect directly to BI tools including **Power BI**, **Tableau**, and **Looker**.

Dashboards built on this architecture can support:

- Sales performance tracking by product, region, and time period
- Customer segmentation and behavior analysis
- Product performance and inventory insights
