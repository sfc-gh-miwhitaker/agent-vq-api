# Getting Started

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Snowflake account | With Cortex Analyst access |
| Role | `SYSADMIN` or equivalent |
| Git integration | `SFE_GIT_API_INTEGRATION` (shared infrastructure) |

## Deployment

### Option A: One-Click Deploy (Recommended)

1. Open `deploy_all.sql` in Snowsight
2. Click **Run All**
3. Confirm the final summary shows "Deployment complete!"

### Option B: Step-by-Step

Run each script individually in Snowsight:

```
sql/01_setup/01_create_schema.sql      -- Schema + warehouse
sql/02_tables/01_sample_data.sql       -- Sample orders + customers
sql/03_semantic_view/01_create_semantic_view.sql  -- Semantic view
sql/04_procedures/01_add_verified_query.sql       -- ADD procedure
sql/04_procedures/02_list_verified_queries.sql    -- LIST procedure
sql/04_procedures/03_remove_verified_query.sql    -- REMOVE procedure
```

## Quick Test

After deployment, verify everything works:

```sql
USE SCHEMA SNOWFLAKE_EXAMPLE.VQ_API;
USE WAREHOUSE SFE_VQ_API_WH;

-- 1. Check sample data
SELECT COUNT(*) AS order_count FROM RAW_ORDERS;
-- Expected: 25

-- 2. Check semantic view exists
SELECT SYSTEM$READ_YAML_FROM_SEMANTIC_VIEW(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS'
) AS yaml_spec;

-- 3. Add a test verified query
CALL ADD_VERIFIED_QUERY(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS',
    'test_query',
    'How many orders are there?',
    'SELECT COUNT(__ORDERS.ORDER_ID) AS total_orders FROM __ORDERS'
);

-- 4. List verified queries
CALL LIST_VERIFIED_QUERIES(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS'
);

-- 5. Remove test query
CALL REMOVE_VERIFIED_QUERY(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS',
    'test_query'
);
```

## Running the Full Demo

Open `sql/05_demo/01_demo_workflow.sql` and run each section step-by-step. The workflow demonstrates:

1. Listing verified queries (empty starting state)
2. Adding three business queries
3. Listing all queries
4. Inspecting raw YAML
5. Updating an existing query
6. Removing a query
7. Bulk loading from a staging table

## Procedure Reference

### ADD_VERIFIED_QUERY

Adds or updates a verified query. If a query with the same name exists, it is replaced.

```sql
CALL ADD_VERIFIED_QUERY(
    '<DB.SCHEMA.SEMANTIC_VIEW>',   -- Fully qualified semantic view name
    '<query_name>',                 -- Unique name for the query
    '<question>',                   -- Natural language question
    '<sql>'                         -- SQL using __tablename references
);
```

**Returns:** Success/error message with action taken and total count.

### LIST_VERIFIED_QUERIES

Returns a table of all verified queries in a semantic view.

```sql
CALL LIST_VERIFIED_QUERIES('<DB.SCHEMA.SEMANTIC_VIEW>');
```

**Returns:** Table with columns `NAME`, `QUESTION`, `SQL_TEXT`.

### REMOVE_VERIFIED_QUERY

Removes a verified query by name.

```sql
CALL REMOVE_VERIFIED_QUERY(
    '<DB.SCHEMA.SEMANTIC_VIEW>',
    '<query_name>'
);
```

**Returns:** Success/error message with remaining count.

## Verified Query SQL Rules

When writing SQL for verified queries:

- **Use logical table names** with double-underscore prefix: `__ORDERS`, `__CUSTOMERS`
- **Use logical column names** as defined in the semantic view (dimensions, facts, metrics)
- **Do NOT use** fully qualified physical table names
- **Escape single quotes** by doubling them: `''Completed''`

### Correct

```sql
'SELECT __ORDERS.PRODUCT, SUM(__ORDERS.TOTAL_AMOUNT) AS revenue
 FROM __ORDERS GROUP BY 1 ORDER BY 2 DESC'
```

### Incorrect

```sql
'SELECT PRODUCT, SUM(TOTAL_AMOUNT) AS revenue
 FROM SNOWFLAKE_EXAMPLE.VQ_API.RAW_ORDERS GROUP BY 1 ORDER BY 2 DESC'
```

## Cleanup

Run `teardown_all.sql` in Snowsight to remove all demo objects.
