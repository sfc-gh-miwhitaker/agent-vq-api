/*==============================================================================
04c - Stored Procedure: REMOVE_VERIFIED_QUERY
Removes a verified query from a semantic view by name.

Usage:
  CALL SNOWFLAKE_EXAMPLE.VQ_API.REMOVE_VERIFIED_QUERY(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS',
    'monthly_revenue'
  );
==============================================================================*/

USE SCHEMA SNOWFLAKE_EXAMPLE.VQ_API;
USE WAREHOUSE SFE_VQ_API_WH;

CREATE OR REPLACE PROCEDURE REMOVE_VERIFIED_QUERY(
    SEMANTIC_VIEW_NAME VARCHAR,   -- Fully qualified: DB.SCHEMA.VIEW
    QUERY_NAME         VARCHAR    -- Name of the verified query to remove
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pyyaml')
HANDLER = 'remove_verified_query'
COMMENT = 'DEMO: Remove a verified query from a semantic view (Expires: 2026-03-07)'
EXECUTE AS CALLER
AS
$$
import yaml
from snowflake.snowpark import Session


def remove_verified_query(
    session: Session,
    semantic_view_name: str,
    query_name: str,
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

    if 'verified_queries' not in sv_spec or not sv_spec['verified_queries']:
        return f"Error: No verified queries found in '{semantic_view_name}'"

    # Find and remove the named query
    original_count = len(sv_spec['verified_queries'])
    sv_spec['verified_queries'] = [
        vq for vq in sv_spec['verified_queries']
        if vq.get('name') != query_name
    ]

    if len(sv_spec['verified_queries']) == original_count:
        return f"Error: Verified query '{query_name}' not found"

    # Clean up empty list
    if not sv_spec['verified_queries']:
        del sv_spec['verified_queries']

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

    remaining = len(sv_spec.get('verified_queries', []))
    return f"Successfully removed verified query '{query_name}' (remaining: {remaining})"
$$;
