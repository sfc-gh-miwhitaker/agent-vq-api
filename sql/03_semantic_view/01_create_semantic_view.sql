/*==============================================================================
03 - Create Semantic View
Creates the base semantic view with NO verified queries.
Verified queries will be added programmatically using the stored procedures.
==============================================================================*/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_VQ_API_WH;

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
    ORDERS.ORDER_ID    COMMENT = 'Unique order identifier',
    ORDERS.CUSTOMER_ID COMMENT = 'Customer foreign key',
    ORDERS.PRODUCT     WITH SYNONYMS = ('product name', 'item')
      COMMENT = 'Product purchased',
    ORDERS.STATUS      WITH SYNONYMS = ('order status')
      COMMENT = 'Order fulfillment status',
    CUSTOMERS.CUSTOMER_ID   COMMENT = 'Unique customer identifier',
    CUSTOMERS.CUSTOMER_NAME WITH SYNONYMS = ('name', 'client')
      COMMENT = 'Full customer name',
    CUSTOMERS.REGION  WITH SYNONYMS = ('area', 'territory')
      COMMENT = 'Geographic sales region',
    CUSTOMERS.SEGMENT WITH SYNONYMS = ('customer type', 'tier')
      COMMENT = 'Customer business segment'
  )
  FACTS (
    ORDERS.ORDER_DATE   WITH SYNONYMS = ('date', 'order time')
      COMMENT = 'Date the order was placed',
    ORDERS.QUANTITY     COMMENT = 'Number of units ordered',
    ORDERS.UNIT_PRICE   COMMENT = 'Price per unit',
    ORDERS.TOTAL_AMOUNT WITH SYNONYMS = ('revenue', 'sales')
      COMMENT = 'Total order amount',
    CUSTOMERS.JOIN_DATE COMMENT = 'Date customer first registered'
  )
  METRICS (
    TOTAL_REVENUE AS SUM(ORDERS.TOTAL_AMOUNT)
      WITH SYNONYMS = ('total sales', 'revenue')
      COMMENT = 'Sum of all order amounts',
    ORDER_COUNT AS COUNT(ORDERS.ORDER_ID)
      WITH SYNONYMS = ('number of orders', 'count of orders')
      COMMENT = 'Total number of orders',
    AVG_ORDER_VALUE AS AVG(ORDERS.TOTAL_AMOUNT)
      WITH SYNONYMS = ('average order', 'AOV')
      COMMENT = 'Average order amount'
  )
  COMMENT = 'DEMO: Order analytics for VQ API demo (Expires: 2026-03-07)';
