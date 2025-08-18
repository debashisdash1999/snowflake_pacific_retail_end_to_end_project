USE pacificretail_db

CREATE SCHEMA IF NOT EXISTS GOLD;

USE pacificretail_db.bronze;

-- Manually executing the tasks ignoring the CRON expression to load data in bronze schema tables
EXECUTE TASK LOAD_CUSTOMER_DATA_TASK;
EXECUTE TASK LOAD_PRODUCT_DATA_TASK;
EXECUTE TASK LOAD_ORDER_DATA_TASK;

SELECT * FROM raw_customer;
SELECT * FROM raw_product;
SELECT * FROM raw_order;

SHOW STREAMS;

SELECT * FROM CUSTOMER_CHANGES_STREAM;



USE pacificretail_db.silver;

SHOW TASKS;

-- Manually executing the tasks ignoring the CRON expression to load data in silver schema tables
EXECUTE TASK ORDER_SILVER_MERGE_TASK;
EXECUTE TASK PRODUCT_SILVER_MERGE_TASK;
EXECUTE TASK SILVER_CUSTOMER_MERGE_TASK;

SELECT * FROM customer;
SELECT * FROM product;
SELECT * FROM orders;
