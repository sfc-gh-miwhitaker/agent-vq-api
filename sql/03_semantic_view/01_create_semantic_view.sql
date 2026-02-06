/*==============================================================================
03 - Create Semantic View
Creates the base semantic view with NO verified queries.
Verified queries will be added programmatically using the stored procedures.
==============================================================================*/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_VQ_API_WH;

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

-- Minimal semantic view following exact docs pattern
CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS

  TABLES (
    orders AS SNOWFLAKE_EXAMPLE.VQ_API.RAW_ORDERS
      PRIMARY KEY (ORDER_ID),
    customers AS SNOWFLAKE_EXAMPLE.VQ_API.RAW_CUSTOMERS
      PRIMARY KEY (CUSTOMER_ID)
  )

  RELATIONSHIPS (
    orders_to_customers AS
      orders (CUSTOMER_ID) REFERENCES customers
  )

  FACTS (
    orders.order_date AS ORDER_DATE,
    orders.quantity AS QUANTITY,
    orders.unit_price AS UNIT_PRICE,
    orders.total_amount AS TOTAL_AMOUNT,
    customers.join_date AS JOIN_DATE
  )

  DIMENSIONS (
    orders.order_id AS ORDER_ID,
    orders.customer_id AS orders.CUSTOMER_ID,
    orders.product AS PRODUCT,
    orders.status AS STATUS,
    customers.customer_id AS customers.CUSTOMER_ID,
    customers.customer_name AS CUSTOMER_NAME,
    customers.region AS REGION,
    customers.segment AS SEGMENT
  )

  METRICS (
    orders.total_revenue AS SUM(TOTAL_AMOUNT)
      COMMENT = 'Sum of all order amounts',
    orders.order_count AS COUNT(ORDER_ID)
      COMMENT = 'Total number of orders',
    orders.avg_order_value AS AVG(TOTAL_AMOUNT)
      COMMENT = 'Average order amount'
  )

  COMMENT = 'DEMO: Order analytics for VQ API demo (Expires: 2026-03-07)';
