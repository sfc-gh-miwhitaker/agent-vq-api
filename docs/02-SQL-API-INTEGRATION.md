# SQL API Integration

The stored procedures can be called via the Snowflake SQL API, enabling external automation and CI/CD integration.

## Authentication

The SQL API uses programmatic access tokens (PAT) for authentication:

```bash
# Set your account and token
export SNOWFLAKE_ACCOUNT="your-account"
export SNOWFLAKE_TOKEN="your-programmatic-access-token"
```

## API Endpoint

```
POST https://<account>.snowflakecomputing.com/api/v2/statements
```

### Required Headers

| Header | Value |
|--------|-------|
| `Authorization` | `Bearer $TOKEN` |
| `Content-Type` | `application/json` |
| `X-Snowflake-Authorization-Token-Type` | `PROGRAMMATIC_ACCESS_TOKEN` |

## Examples

### Add a Verified Query

```bash
curl -X POST "https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/api/v2/statements" \
  -H "Authorization: Bearer ${SNOWFLAKE_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
  -d '{
    "statement": "CALL SNOWFLAKE_EXAMPLE.VQ_API.ADD_VERIFIED_QUERY('\''SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS'\'', '\''monthly_revenue'\'', '\''What is the total revenue by month?'\'', '\''SELECT DATE_TRUNC(''''month'''', __ORDERS.ORDER_DATE) AS month, SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue FROM __ORDERS GROUP BY 1 ORDER BY 1'\'')",
    "warehouse": "SFE_VQ_API_WH",
    "database": "SNOWFLAKE_EXAMPLE",
    "schema": "VQ_API",
    "role": "SYSADMIN"
  }'
```

### List Verified Queries

```bash
curl -X POST "https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/api/v2/statements" \
  -H "Authorization: Bearer ${SNOWFLAKE_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
  -d '{
    "statement": "CALL SNOWFLAKE_EXAMPLE.VQ_API.LIST_VERIFIED_QUERIES('\''SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS'\'')",
    "warehouse": "SFE_VQ_API_WH",
    "database": "SNOWFLAKE_EXAMPLE",
    "schema": "VQ_API",
    "role": "SYSADMIN"
  }'
```

### Remove a Verified Query

```bash
curl -X POST "https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/api/v2/statements" \
  -H "Authorization: Bearer ${SNOWFLAKE_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
  -d '{
    "statement": "CALL SNOWFLAKE_EXAMPLE.VQ_API.REMOVE_VERIFIED_QUERY('\''SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS'\'', '\''monthly_revenue'\'')",
    "warehouse": "SFE_VQ_API_WH",
    "database": "SNOWFLAKE_EXAMPLE",
    "schema": "VQ_API",
    "role": "SYSADMIN"
  }'
```

## Checking Statement Status

The SQL API is asynchronous. After submitting a statement, poll for results:

```bash
# Submit and capture the statement handle
HANDLE=$(curl -s -X POST "https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/api/v2/statements" \
  -H "Authorization: Bearer ${SNOWFLAKE_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
  -d '{
    "statement": "CALL SNOWFLAKE_EXAMPLE.VQ_API.LIST_VERIFIED_QUERIES('\''SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS'\'')",
    "warehouse": "SFE_VQ_API_WH",
    "role": "SYSADMIN"
  }' | jq -r '.statementHandle')

# Poll for results
curl -s "https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/api/v2/statements/${HANDLE}" \
  -H "Authorization: Bearer ${SNOWFLAKE_TOKEN}" \
  -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" | jq .
```

## Automation Patterns

### CI/CD Pipeline

Load verified queries from a version-controlled JSON file:

```bash
#!/bin/bash
# load_verified_queries.sh
# Reads queries from a JSON file and loads them via SQL API

VQ_FILE="verified_queries.json"
SV_NAME="SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS"

jq -c '.[]' "$VQ_FILE" | while read -r query; do
    NAME=$(echo "$query" | jq -r '.name')
    QUESTION=$(echo "$query" | jq -r '.question')
    SQL=$(echo "$query" | jq -r '.sql')

    echo "Loading verified query: ${NAME}"

    curl -s -X POST "https://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/api/v2/statements" \
      -H "Authorization: Bearer ${SNOWFLAKE_TOKEN}" \
      -H "Content-Type: application/json" \
      -H "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
      -d "{
        \"statement\": \"CALL SNOWFLAKE_EXAMPLE.VQ_API.ADD_VERIFIED_QUERY('${SV_NAME}', '${NAME}', '${QUESTION}', '${SQL}')\",
        \"warehouse\": \"SFE_VQ_API_WH\",
        \"role\": \"SYSADMIN\"
      }"

    echo ""
done
```

### Example verified_queries.json

```json
[
  {
    "name": "monthly_revenue",
    "question": "What is the total revenue by month?",
    "sql": "SELECT DATE_TRUNC('month', __ORDERS.ORDER_DATE) AS month, SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue FROM __ORDERS GROUP BY 1 ORDER BY 1"
  },
  {
    "name": "top_products",
    "question": "What are the top products by revenue?",
    "sql": "SELECT __ORDERS.PRODUCT, SUM(__ORDERS.TOTAL_AMOUNT) AS revenue FROM __ORDERS GROUP BY 1 ORDER BY 2 DESC"
  }
]
```

## Grant Requirements

The role executing the procedures needs:

| Privilege | Object | Purpose |
|-----------|--------|---------|
| `USAGE` | `SNOWFLAKE_EXAMPLE` database | Access database |
| `USAGE` | `VQ_API` schema | Access procedures |
| `USAGE` | `SEMANTIC_MODELS` schema | Access semantic views |
| `SELECT` | Semantic view | Read YAML spec |
| `SELECT` | Underlying tables | Validate queries |
| `OWNERSHIP` or `CREATE SEMANTIC VIEW` | `SEMANTIC_MODELS` schema | Recreate semantic view |
