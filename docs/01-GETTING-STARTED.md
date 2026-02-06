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

## External API Management

After deploying the Snowflake objects, you can manage verified queries from any external system using the Python CLI.

### Setup

```bash
pip install -r requirements.txt

export SNOWFLAKE_ACCOUNT='myorg-myaccount'
export SNOWFLAKE_PAT='your-programmatic-access-token'
```

### Commands

```bash
# List current verified queries
python tools/vq_manager.py list

# Add a single query
python tools/vq_manager.py add monthly_revenue \
    "What is the total revenue by month?" \
    "SELECT DATE_TRUNC('month', __ORDERS.ORDER_DATE) AS month, SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue FROM __ORDERS GROUP BY 1 ORDER BY 1"

# Bulk load from the sample JSON file
python tools/vq_manager.py bulk-load tools/verified_queries.json

# Backup current queries to a file
python tools/vq_manager.py backup my_backup.json

# Remove a query
python tools/vq_manager.py remove monthly_revenue
```

### Custom Semantic View

By default the CLI targets `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS`. Override with:

```bash
export SNOWFLAKE_SV='MY_DB.MY_SCHEMA.MY_SEMANTIC_VIEW'
```

### CI/CD Pattern

Use `bulk-load` + `backup` in a pipeline to version-control your verified queries:

1. Store `verified_queries.json` in source control
2. On merge to main, run `python tools/vq_manager.py bulk-load verified_queries.json`
3. Before changes, run `python tools/vq_manager.py backup` to snapshot the current state

## Cleanup

Run `teardown_all.sql` in Snowsight to remove all demo objects.
