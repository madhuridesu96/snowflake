USE ROLE ACCOUNTADMIN;

SELECT CURRENT_USER();
CREATE ROLE IF NOT EXISTS data_engineer;
CREATE ROLE IF NOT EXISTS data_analyst;

-- Why inherit into SYSADMIN instead of granting only to a user:
-- SYSADMIN is meant to own and manage all databases, warehouses and objects.
-- Granting custom roles to SYSADMIN keeps one clean hierarchy, so admins can
-- see and manage everything these roles create. If a role is granted only to
-- a user, its objects become "orphaned" and hard to manage if that person leaves.
GRANT ROLE data_engineer TO ROLE SYSADMIN;
GRANT ROLE data_analyst  TO ROLE SYSADMIN;
-- Data engineer: can use database, schema, warehouse, and create tables
GRANT USAGE ON DATABASE  retail_lakehouse        TO ROLE data_engineer;
GRANT USAGE ON SCHEMA    retail_lakehouse.bronze TO ROLE data_engineer;
GRANT USAGE ON WAREHOUSE learn_wh                TO ROLE data_engineer;
GRANT CREATE TABLE ON SCHEMA retail_lakehouse.bronze TO ROLE data_engineer;

-- Data analyst: same USAGE grants, but no CREATE (read-only)
GRANT USAGE ON DATABASE  retail_lakehouse        TO ROLE data_analyst;
GRANT USAGE ON SCHEMA    retail_lakehouse.bronze TO ROLE data_analyst;
GRANT USAGE ON WAREHOUSE learn_wh                TO ROLE data_analyst;

-- Give both roles to yourself so you can switch between them
GRANT ROLE data_engineer TO USER MADHURI;
GRANT ROLE data_analyst  TO USER MADHURI;
GRANT SELECT ON FUTURE TABLES IN SCHEMA retail_lakehouse.bronze TO ROLE data_analyst;
-- Check the setup
SHOW GRANTS TO ROLE data_engineer;
SHOW GRANTS TO ROLE data_analyst;
SHOW FUTURE GRANTS IN SCHEMA retail_lakehouse.bronze;

-- Test switching roles
USE ROLE data_engineer;
SELECT CURRENT_ROLE();

USE ROLE data_analyst;
SELECT CURRENT_ROLE();

USE ROLE ACCOUNTADMIN;
