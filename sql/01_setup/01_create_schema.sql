/*==============================================================================
01 - Create Schema and Warehouse
==============================================================================*/

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE;

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.VQ_API
  COMMENT = 'DEMO: Verified Query API procedures and sample data (Expires: 2026-03-07)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
  COMMENT = 'Shared semantic views for demos';

CREATE WAREHOUSE IF NOT EXISTS SFE_VQ_API_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'DEMO: Verified Query API compute (Expires: 2026-03-07)';

USE SCHEMA SNOWFLAKE_EXAMPLE.VQ_API;
USE WAREHOUSE SFE_VQ_API_WH;
