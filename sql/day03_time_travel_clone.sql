-- =====================================================================
-- Day 3: Time Travel, UNDROP and Zero-Copy Cloning
-- =====================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE learn_wh;

-- ---------------------------------------------------------------------
-- Add the medallion schemas (Silver = cleaned, Gold = reporting)
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS retail_lakehouse.silver;
CREATE SCHEMA IF NOT EXISTS retail_lakehouse.gold;

USE SCHEMA retail_lakehouse.bronze;

-- ---------------------------------------------------------------------
-- Step 2: Time Travel (AT and BEFORE)
-- ---------------------------------------------------------------------
--  Make sure the name starts as 'Asha Rao'
UPDATE retail_lakehouse.bronze.customers
   SET full_name = 'Asha Rao'
 WHERE customer_id = 1;

SELECT * FROM retail_lakehouse.bronze.customers WHERE customer_id = 1;

-- Change the row and save its query ID (highlight both, run together)
UPDATE retail_lakehouse.bronze.customers
   SET full_name = 'Asha Rao UPDATED'
 WHERE customer_id = 1;
SET change_qid = LAST_QUERY_ID();

-- Current data: shows the new name
SELECT * FROM retail_lakehouse.bronze.customers WHERE customer_id = 1;

-- AT: the table 60 seconds ago (run within 60 seconds of 2b)
SELECT * FROM retail_lakehouse.bronze.customers AT(OFFSET => -60) WHERE customer_id = 1;

--  BEFORE: the table just before the UPDATE ran
SELECT * FROM retail_lakehouse.bronze.customers BEFORE(STATEMENT => $change_qid) WHERE customer_id = 1;

-- Put the original name back
UPDATE retail_lakehouse.bronze.customers
   SET full_name = 'Asha Rao'
 WHERE customer_id = 1;

 -- ---------------------------------------------------------------------
--  Drop and recover with UNDROP
-- ---------------------------------------------------------------------
SELECT COUNT(*) FROM retail_lakehouse.bronze.customers;   -- before drop

DROP TABLE retail_lakehouse.bronze.customers;

UNDROP TABLE retail_lakehouse.bronze.customers;

SELECT COUNT(*) FROM retail_lakehouse.bronze.customers;   -- data is back

-- ---------------------------------------------------------------------
-- Step 4: Zero-copy clone of the whole bronze schema
-- ---------------------------------------------------------------------
CREATE OR REPLACE SCHEMA retail_lakehouse.bronze_clone CLONE retail_lakehouse.bronze;

-- Change a row in the CLONE only
UPDATE retail_lakehouse.bronze_clone.customers
   SET full_name = 'Chen Li CLONE EDIT'
 WHERE customer_id = 3;

-- Clone: shows the edit
SELECT * FROM retail_lakehouse.bronze_clone.customers WHERE customer_id = 3;

-- Original: still 'Chen Li'
SELECT * FROM retail_lakehouse.bronze.customers WHERE customer_id = 3;

-- Why: a clone shares the original's storage at creation (nothing is copied).
-- When the clone changes, only the changed parts are stored separately
-- (copy-on-write). The clone is independent, not a live view of the original.
