 SELECT CURRENT_ACCOUNT(), CURRENT_REGION(), CURRENT_VERSION();

-- AUTO_SUSPEND = 60 stops the warehouse after 60 seconds of inactivity,
-- so it doesn't burn credits while idle. With only $400 in trial credits,
-- this keeps costs low. AUTO_RESUME = TRUE restarts it automatically
-- when the next query runs.
CREATE WAREHOUSE IF NOT EXISTS learn_wh
  WITH WAREHOUSE_SIZE = 'XSMALL'
       AUTO_SUSPEND   = 60
       AUTO_RESUME    = TRUE
  COMMENT = 'XS + 60s auto-suspend to protect trial credits';

USE WAREHOUSE learn_wh;
SHOW DATABASES;
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS LIMIT 10;

SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER LIMIT 10;

SELECT COUNT(*) FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS;
CREATE DATABASE IF NOT EXISTS retail_lakehouse;

CREATE SCHEMA IF NOT EXISTS retail_lakehouse.bronze;
