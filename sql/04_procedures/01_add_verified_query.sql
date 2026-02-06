/*==============================================================================
04a - Stored Procedure: ADD_VERIFIED_QUERY
Adds or updates a verified query in a semantic view.

Usage:
  CALL SNOWFLAKE_EXAMPLE.VQ_API.ADD_VERIFIED_QUERY(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS',
    'monthly_revenue',
    'What is the total revenue by month?',
    'SELECT DATE_TRUNC(''month'', __ORDERS.ORDER_DATE) AS month,
            SUM(__ORDERS.TOTAL_AMOUNT) AS total_revenue
     FROM __ORDERS GROUP BY 1 ORDER BY 1'
  );
==============================================================================*/

USE SCHEMA SNOWFLAKE_EXAMPLE.VQ_API;
USE WAREHOUSE SFE_VQ_API_WH;

CREATE OR REPLACE PROCEDURE ADD_VERIFIED_QUERY(
    SEMANTIC_VIEW_NAME VARCHAR,   -- Fully qualified: DB.SCHEMA.VIEW
    QUERY_NAME         VARCHAR,   -- Unique identifier for the query
    QUESTION           VARCHAR,   -- Natural language question
    SQL_QUERY          VARCHAR    -- SQL using logical table names (__tablename)
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pyyaml')
HANDLER = 'add_verified_query'
COMMENT = 'DEMO: Add or update a verified query in a semantic view (Expires: 2026-03-07)'
EXECUTE AS CALLER
AS
$$
import yaml
from snowflake.snowpark import Session


def add_verified_query(
    session: Session,
    semantic_view_name: str,
    query_name: str,
    question: str,
    sql_query: str,
) -> str:
    # Parse fully qualified name
    parts = semantic_view_name.replace('"', '').split('.')
    if len(parts) != 3:
        return "Error: Name must be fully qualified (DB.SCHEMA.VIEW)"

    db_name, schema_name, view_name = parts
    fully_qualified_schema = f"{db_name}.{schema_name}"

    # Read current YAML
    try:
        result = session.sql(
            f"SELECT SYSTEM$READ_YAML_FROM_SEMANTIC_VIEW('{semantic_view_name}')"
        ).collect()
        current_yaml = result[0][0]
    except Exception as e:
        return f"Error reading semantic view: {e}"

    # Parse and modify YAML
    sv_spec = yaml.safe_load(current_yaml)

    new_vq = {
        'name': query_name,
        'question': question,
        'sql': sql_query,
    }

    if 'verified_queries' not in sv_spec:
        sv_spec['verified_queries'] = []

    # Check for existing query with same name - update or append
    # Case-insensitive: Snowflake may uppercase names in YAML round-trip
    existing_names = [vq.get('name', '').upper() for vq in sv_spec['verified_queries']]
    if query_name.upper() in existing_names:
        for i, vq in enumerate(sv_spec['verified_queries']):
            if vq.get('name', '').upper() == query_name.upper():
                sv_spec['verified_queries'][i] = new_vq
                break
        action = "updated"
    else:
        sv_spec['verified_queries'].append(new_vq)
        action = "added"

    # Recreate semantic view from modified YAML
    updated_yaml = yaml.dump(
        sv_spec,
        default_flow_style=False,
        allow_unicode=True,
        sort_keys=False,
    )
    escaped_yaml = updated_yaml.replace("'", "''")

    try:
        session.sql(
            f"CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML("
            f"'{fully_qualified_schema}', '{escaped_yaml}')"
        ).collect()
    except Exception as e:
        return f"Error recreating semantic view: {e}"

    count = len(sv_spec['verified_queries'])
    return f"Successfully {action} verified query '{query_name}' (total: {count})"
$$;
