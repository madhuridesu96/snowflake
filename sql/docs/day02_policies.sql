  -- =====================================================
--Masking and Row Access Policies
-- =====================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE learn_wh;
USE SCHEMA retail_lakehouse.bronze;

-- Start clean: remove the old table (and its duplicate rows)
DROP TABLE IF EXISTS retail_lakehouse.bronze.customers;

-- Step 4a: Synthetic customer table (fake data only)
CREATE TABLE retail_lakehouse.bronze.customers (
  customer_id INT,
  full_name   STRING,
  email       STRING,
  region      STRING
);

INSERT OVERWRITE INTO retail_lakehouse.bronze.customers VALUES
  (1, 'Asha Rao',    'asha.rao@example.com',    'EAST'),
  (2, 'Ben Carter',  'ben.carter@example.com',  'WEST'),
  (3, 'Chen Li',     'chen.li@example.com',     'EAST'),
  (4, 'Diya Patel',  'diya.patel@example.com',  'SOUTH'),
  (5, 'Eli Johnson', 'eli.johnson@example.com', 'WEST'),
  (6, 'Fatima Khan', 'fatima.khan@example.com', 'EAST');

-- Check: must be 6
SELECT COUNT(*) FROM retail_lakehouse.bronze.customers;

-- data_analyst reads via the future grant; data_engineer needs this grant
GRANT SELECT ON TABLE retail_lakehouse.bronze.customers TO ROLE data_engineer;

-- Step 4b: Masking policy on email
CREATE MASKING POLICY IF NOT EXISTS mask_email AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_ENGINEER') THEN val
    ELSE '***MASKED***'
  END;

ALTER TABLE retail_lakehouse.bronze.customers
  MODIFY COLUMN email SET MASKING POLICY mask_email;

-- Step 5: Row access policy on region
CREATE ROW ACCESS POLICY IF NOT EXISTS region_policy AS (region STRING) RETURNS BOOLEAN ->
  CURRENT_ROLE() = 'DATA_ENGINEER' OR region = 'EAST';

ALTER TABLE retail_lakehouse.bronze.customers
  ADD ROW ACCESS POLICY region_policy ON (region);

-- Test as DATA_ENGINEER: expect real emails, 6 rows
USE ROLE data_engineer;
SELECT CURRENT_ROLE(), * FROM retail_lakehouse.bronze.customers;
SELECT COUNT(*) FROM retail_lakehouse.bronze.customers;

-- Test as DATA_ANALYST: expect ***MASKED*** emails, 3 rows
USE ROLE data_analyst;
SELECT CURRENT_ROLE(), * FROM retail_lakehouse.bronze.customers;
SELECT COUNT(*) FROM retail_lakehouse.bronze.customers;

SELECT policy_name, policy_kind, ref_column_name
FROM TABLE(
  retail_lakehouse.INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_NAME   => 'retail_lakehouse.bronze.customers',
    REF_ENTITY_DOMAIN => 'table'
  )
);

USE ROLE ACCOUNTADMIN;
