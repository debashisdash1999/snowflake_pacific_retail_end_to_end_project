USE pacificretail_db.bronze;

/* These streams will be used to know any new incoming files in our bronze schema tables(raw tables data), 
as we will get incremental data load to this layer as per our task(cron) */

CREATE OR REPLACE STREAM customer_changes_stream ON TABLE raw_customer
    APPEND_ONLY = TRUE;


CREATE OR REPLACE STREAM product_changes_stream ON TABLE raw_product
    APPEND_ONLY = TRUE;

    
CREATE OR REPLACE STREAM order_changes_stream ON TABLE raw_order
    APPEND_ONLY = TRUE;

    
SHOW STREAMS IN pacificretail_db.bronze;

    