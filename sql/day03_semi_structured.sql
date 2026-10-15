-- =====================================================================
-- Day 3: Semi-Structured Data (VARIANT, dot notation, FLATTEN)
-- =====================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE learn_wh;
USE SCHEMA retail_lakehouse.bronze;

-- A stage is a holding area for files before loading
CREATE STAGE IF NOT EXISTS retail_lakehouse.bronze.json_stage;

-- A table with ONE column named raw, type VARIANT (holds whole JSON)
CREATE OR REPLACE TABLE retail_lakehouse.bronze.raw_orders (
  raw VARIANT
);
COPY INTO retail_lakehouse.bronze.raw_orders
  FROM @retail_lakehouse.bronze.json_stage
  FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE);
SELECT * FROM retail_lakehouse.bronze.raw_orders;
SELECT raw:customer.id, raw:customer.address.city
FROM retail_lakehouse.bronze.raw_orders;
SELECT
  raw:order_id::INT                  AS order_id,
  raw:customer.id::STRING            AS customer_id,
  raw:customer.name::STRING          AS customer_name,
  raw:customer.address.city::STRING  AS city
FROM retail_lakehouse.bronze.raw_orders;
-- ---------------------------------------------------------------------
-- Step 6: One row per line item with LATERAL FLATTEN
-- ---------------------------------------------------------------------
SELECT value:item_id, value:qty
FROM retail_lakehouse.bronze.raw_orders,
     LATERAL FLATTEN(input => raw:line_items);
SELECT
  raw:order_id::INT          AS order_id,
  value:item_id::STRING      AS item_id,
  value:product::STRING      AS product,
  value:qty::INT             AS qty,
  value:price::NUMBER(10,2)  AS price
FROM retail_lakehouse.bronze.raw_orders,
     LATERAL FLATTEN(input => raw:line_items);
-- ---------------------------------------------------------------------
-- Step 7: Clustering check on a larger table (1.5M rows)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE retail_lakehouse.bronze.orders AS
  SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;

SELECT COUNT(*) FROM retail_lakehouse.bronze.orders;

SELECT SYSTEM$CLUSTERING_INFORMATION('retail_lakehouse.bronze.orders', '(o_orderdate)');

-- Why a manual clustering key is premature here:
-- At 1.5M rows this table is small, so queries already scan little data.
-- A clustering key turns on Automatic Clustering, which keeps reorganizing
-- the table in the background and uses credits continuously. It only pays
-- off on very large tables (terabytes) filtered heavily on the same column.
-- Here it would spend trial credits for no real benefit.
