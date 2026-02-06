/*==============================================================================
05 - Demo Workflow: Verified Query CRUD Operations
Run each section step-by-step to demonstrate the full lifecycle.
==============================================================================*/

USE SCHEMA SNOWFLAKE_EXAMPLE.VQ_API;
USE WAREHOUSE SFE_VQ_API_WH;

SET SV_NAME = 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS';

----------------------------------------------------------------------
-- STEP 1: Verify starting state (no verified queries)
----------------------------------------------------------------------
CALL LIST_VERIFIED_QUERIES($SV_NAME);


----------------------------------------------------------------------
-- STEP 2: Add first verified query - monthly revenue
----------------------------------------------------------------------
CALL ADD_VERIFIED_QUERY(
    $SV_NAME,
    'monthly_revenue',
    'What is the total revenue by month?',
    'SELECT DATE_TRUNC(''month'', __ORDERS.ORDER_DATE) AS month,
            SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue
     FROM __ORDERS
     GROUP BY 1
     ORDER BY 1'
);


----------------------------------------------------------------------
-- STEP 3: Add second verified query - revenue by region
----------------------------------------------------------------------
CALL ADD_VERIFIED_QUERY(
    $SV_NAME,
    'revenue_by_region',
    'Which region has the most revenue?',
    'SELECT __CUSTOMERS.REGION,
            SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue,
            COUNT(__ORDERS.ORDER_ID) AS order_count
     FROM __ORDERS
       JOIN __CUSTOMERS
         ON __ORDERS.CUSTOMER_ID = __CUSTOMERS.CUSTOMER_ID
     GROUP BY 1
     ORDER BY 2 DESC'
);


----------------------------------------------------------------------
-- STEP 4: Add third verified query - top products
----------------------------------------------------------------------
CALL ADD_VERIFIED_QUERY(
    $SV_NAME,
    'top_products',
    'What are the top products by total revenue?',
    'SELECT __ORDERS.PRODUCT,
            SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue,
            COUNT(__ORDERS.ORDER_ID) AS order_count
     FROM __ORDERS
     GROUP BY 1
     ORDER BY 2 DESC'
);


----------------------------------------------------------------------
-- STEP 5: List all verified queries (should show 3)
----------------------------------------------------------------------
CALL LIST_VERIFIED_QUERIES($SV_NAME);


----------------------------------------------------------------------
-- STEP 6: Verify the YAML directly (optional - see raw representation)
----------------------------------------------------------------------
SELECT SYSTEM$READ_YAML_FROM_SEMANTIC_VIEW($SV_NAME) AS yaml_spec;


----------------------------------------------------------------------
-- STEP 7: Update an existing verified query (same name = replace)
----------------------------------------------------------------------

-- Snapshot before the update
CREATE OR REPLACE TEMPORARY TABLE VQ_BEFORE AS
    SELECT NAME, QUESTION, SQL_TEXT
    FROM TABLE(LIST_VERIFIED_QUERIES($SV_NAME));

CALL ADD_VERIFIED_QUERY(
    $SV_NAME,
    'monthly_revenue',
    'What is the total revenue by month for completed orders only?',
    'SELECT DATE_TRUNC(''month'', __ORDERS.ORDER_DATE) AS month,
            SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue
     FROM __ORDERS
     WHERE __ORDERS.STATUS = ''Completed''
     GROUP BY 1
     ORDER BY 1'
);

-- Diff: before vs after for the updated query
SELECT 'BEFORE' AS VERSION, b.QUESTION, b.SQL_TEXT
FROM VQ_BEFORE b
WHERE b.NAME = 'monthly_revenue'
UNION ALL
SELECT 'AFTER' AS VERSION, a.QUESTION, a.SQL_TEXT
FROM TABLE(LIST_VERIFIED_QUERIES($SV_NAME)) a
WHERE a.NAME = 'monthly_revenue';


----------------------------------------------------------------------
-- STEP 8: Remove a verified query
----------------------------------------------------------------------
CALL REMOVE_VERIFIED_QUERY($SV_NAME, 'top_products');

-- Verify removal (should show 2 remaining)
CALL LIST_VERIFIED_QUERIES($SV_NAME);


----------------------------------------------------------------------
-- STEP 9: Bulk add from a table (advanced pattern)
----------------------------------------------------------------------

-- Create a staging table for bulk verified queries
CREATE OR REPLACE TEMPORARY TABLE VQ_STAGING (
    QUERY_NAME VARCHAR NOT NULL,
    QUESTION   VARCHAR NOT NULL,
    SQL_QUERY  VARCHAR NOT NULL
) COMMENT = 'Temporary staging for bulk verified query loading';

INSERT INTO VQ_STAGING (QUERY_NAME, QUESTION, SQL_QUERY)
VALUES
    ('enterprise_orders',
     'How many orders come from enterprise customers?',
     'SELECT COUNT(__ORDERS.ORDER_ID) AS enterprise_orders
      FROM __ORDERS
        JOIN __CUSTOMERS
          ON __ORDERS.CUSTOMER_ID = __CUSTOMERS.CUSTOMER_ID
      WHERE __CUSTOMERS.SEGMENT = ''Enterprise'''),
    ('avg_order_by_segment',
     'What is the average order value by customer segment?',
     'SELECT __CUSTOMERS.SEGMENT,
             AVG(__ORDERS.TOTAL_AMOUNT) AS avg_order_value,
             COUNT(__ORDERS.ORDER_ID) AS order_count
      FROM __ORDERS
        JOIN __CUSTOMERS
          ON __ORDERS.CUSTOMER_ID = __CUSTOMERS.CUSTOMER_ID
      GROUP BY 1
      ORDER BY 2 DESC');

-- Load each staged query using a cursor
DECLARE
    c1 CURSOR FOR
        SELECT QUERY_NAME, QUESTION, SQL_QUERY
        FROM VQ_STAGING;
    v_name    VARCHAR;
    v_question VARCHAR;
    v_sql     VARCHAR;
    v_result  VARCHAR;
BEGIN
    OPEN c1;
    FOR row_var IN c1 DO
        v_name     := row_var.QUERY_NAME;
        v_question := row_var.QUESTION;
        v_sql      := row_var.SQL_QUERY;
        CALL ADD_VERIFIED_QUERY($SV_NAME, :v_name, :v_question, :v_sql);
    END FOR;
    CLOSE c1;
END;

-- Verify final state (should show 4 verified queries)
CALL LIST_VERIFIED_QUERIES($SV_NAME);
