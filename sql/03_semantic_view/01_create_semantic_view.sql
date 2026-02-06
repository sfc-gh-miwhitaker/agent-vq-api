/*==============================================================================
03 - Create Semantic View
Creates the base semantic view with NO verified queries.
Verified queries will be added programmatically using the stored procedures.
==============================================================================*/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_VQ_API_WH;

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS
  TABLES (
    ORDERS AS SNOWFLAKE_EXAMPLE.VQ_API.RAW_ORDERS
      PRIMARY KEY (ORDER_ID)
      COMMENT = 'Customer orders with product and revenue details',
    CUSTOMERS AS SNOWFLAKE_EXAMPLE.VQ_API.RAW_CUSTOMERS
      PRIMARY KEY (CUSTOMER_ID)
      COMMENT = 'Customer demographic information'
  )
  RELATIONSHIPS (
    orders_to_customers AS
      ORDERS (CUSTOMER_ID) REFERENCES CUSTOMERS (CUSTOMER_ID)
  )
  DIMENSIONS (
    ORDERS.order_id AS ORDERS.ORDER_ID
      COMMENT = 'Unique order identifier',
    ORDERS.customer_id AS ORDERS.CUSTOMER_ID
      COMMENT = 'Customer foreign key',
    ORDERS.product AS ORDERS.PRODUCT
      WITH SYNONYMS = ('product name', 'item')
      COMMENT = 'Product purchased',
    ORDERS.status AS ORDERS.STATUS
      WITH SYNONYMS = ('order status')
      COMMENT = 'Order fulfillment status',
    CUSTOMERS.customer_id AS CUSTOMERS.CUSTOMER_ID
      COMMENT = 'Unique customer identifier',
    CUSTOMERS.customer_name AS CUSTOMERS.CUSTOMER_NAME
      WITH SYNONYMS = ('name', 'client')
      COMMENT = 'Full customer name',
    CUSTOMERS.region AS CUSTOMERS.REGION
      WITH SYNONYMS = ('area', 'territory')
      COMMENT = 'Geographic sales region',
    CUSTOMERS.segment AS CUSTOMERS.SEGMENT
      WITH SYNONYMS = ('customer type', 'tier')
      COMMENT = 'Customer business segment'
  )
  FACTS (
    ORDERS.order_date AS ORDERS.ORDER_DATE
      WITH SYNONYMS = ('date', 'order time')
      COMMENT = 'Date the order was placed',
    ORDERS.quantity AS ORDERS.QUANTITY
      COMMENT = 'Number of units ordered',
    ORDERS.unit_price AS ORDERS.UNIT_PRICE
      COMMENT = 'Price per unit',
    ORDERS.total_amount AS ORDERS.TOTAL_AMOUNT
      WITH SYNONYMS = ('revenue', 'sales')
      COMMENT = 'Total order amount',
    CUSTOMERS.join_date AS CUSTOMERS.JOIN_DATE
      COMMENT = 'Date customer first registered'
  )
  METRICS (
    ORDERS.total_revenue AS SUM(ORDERS.TOTAL_AMOUNT)
      WITH SYNONYMS = ('total sales', 'revenue')
      COMMENT = 'Sum of all order amounts',
    ORDERS.order_count AS COUNT(ORDERS.ORDER_ID)
      WITH SYNONYMS = ('number of orders', 'count of orders')
      COMMENT = 'Total number of orders',
    ORDERS.avg_order_value AS AVG(ORDERS.TOTAL_AMOUNT)
      WITH SYNONYMS = ('average order', 'AOV')
      COMMENT = 'Average order amount'
  )
  COMMENT = 'DEMO: Order analytics for VQ API demo (Expires: 2026-03-07)';
