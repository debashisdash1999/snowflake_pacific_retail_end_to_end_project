# PacificRetail: End-to-End Snowflake Data Engineering Project
Follow the sql files chronologically along with this readme to know about the project workflow.

## Project Overview
**PacificRetail** is an ecommerce company operating across **15 countries (North America & Europe)**, with:
- **5M+ active customers**
- **100,000+ products** in catalog

### Challenges
- **Data silos**: Customer, product, and transaction data stored in separate systems → no holistic view  
- **Processing delays**: Batch processing causes **24-hour delay** in sales & analytics reporting  
- **Scalability issues**: On-premises warehouse struggles during peak sales  
- **Data quality inconsistencies**  
- **Limited analytics capabilities**

### Goals
Implement a **modern data engineering solution using Snowflake** to:
- Centralize all data  
- Enable **real-time analytics**  
- Improve scalability  
- Enhance data quality  
- Support **advanced analytics & ML models**

---

## Data Sources
- **Customer Data** → Daily CSV files (~100K records/day)  
- **Product Catalog** → Hourly JSON files (~10K changes/day)  
- **Transaction Logs** → Real-time Parquet files (~500K transactions/day)

---

## Expected Outcomes
- Reduce data processing time: **24 hours → < 1 hour**  
- Achieve **99.9% accuracy** in cross-channel reporting  
- Scale to handle **5x current data volume**  
- Enable **self-service analytics**  
- Provide foundation for **ML models**

---

## Architecture Overview
**Layers:**
- **Bronze Layer** → Raw data ingestion  
- **Silver Layer** → Cleaned & conformed data  
- **Gold Layer** → Business-level aggregates & data marts  

### High-Level Architecture
1. **Data Sources**  
   - CRM → Customer data  
   - Inventory system → Product catalog  
   - E-commerce platform → Transaction data  

2. **Azure Data Lake Storage (ADLS)**  
   - Centralized data lake  
   - Stores raw files in multiple formats (CSV, JSON, Parquet)  
   - Acts as staging area for Snowflake  

3. **Snowflake Data Warehouse**  
   - Connects to ADLS via **External Stages**  
   - Ingests using **COPY command**  
   - Organizes data into **Bronze → Silver → Gold schemas**  
   - Provides compute resources for analytics  

4. **Data Processing Layers**
   - **Bronze Layer**: Raw ingestion, no transformations, preserves original structure  
   - **Silver Layer**:  
     - Cleansed & standardized data  
     - Implements **CDC (Change Data Capture) with MERGE**  
     - Data quality checks (validations, standardization)  
   - **Gold Layer**:  
     - Business-specific **aggregates**  
     - Denormalized & query-friendly structure  
     - Optimized for BI tools  

---

## Data Flow
Source Systems → ADLS → Bronze Layer → Silver Layer → Gold Layer → BI Tools


### Transformations & Validations
**Customer Table**
- Email validation (not null)  
- Customer type normalization (`regular`, `premium`, `unknown`)  
- Age check (18–120)  
- Gender standardization (`male`, `female`, `other`)  
- Total purchases validation (numeric, default 0 if invalid)  

**Product Table**
- Price validation (positive number)  
- Stock validation (non-negative)  
- Rating validation (0–5)  

**Implementation:**  
- Stored Procedures + Tasks for automated validation and transformations  

---

## Gold Layer Views

### 1. Daily Sales Analysis
```snowflake
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
```snowflake
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

- **External Stages** – Integrating ADLS  
- **COPY Command** – Bulk loading  
- **Streams** – CDC implementation  
- **Tasks** – Scheduled automation  
- **Stored Procedures** – Business logic & validation  
- **Time Travel** – Querying historical data  
- **Zero-Copy Cloning** – Testing & dev without data duplication  

---

## Benefits of this Architecture

- **Scalability**: Handles current + 5x projected data growth  
- **Flexibility**: Works across diverse data formats & sources  
- **Performance**: Reduced processing time from 24 hours to < 1 hour  
- **Cost Efficiency**: Separation of compute and storage  
- **Data Governance**: Improved quality, consistency, and auditing  

---

## Key Components

- **Snowflake Database**  
- **External Stage (ADLS integration)**  
- **Schemas**: Bronze, Silver, Gold  
- **Tables**  
- **Tasks**  
- **Streams**  
- **Views**  

---

## Reporting & Analytics

Final outputs from the **Gold Layer** are consumed by BI tools such as:  

- Power BI  
- Tableau  
- Looker  

### Actionable Dashboards Provide Insights Into:
- **Sales performance tracking**  
- **Customer segmentation & behavior analysis**  
- **Product performance & inventory insights**  
