/*==============================================================================
04b - Stored Procedure: LIST_VERIFIED_QUERIES
Lists all verified queries in a semantic view.

Usage:
  CALL SNOWFLAKE_EXAMPLE.VQ_API.LIST_VERIFIED_QUERIES(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS'
  );
==============================================================================*/

USE SCHEMA SNOWFLAKE_EXAMPLE.VQ_API;
USE WAREHOUSE SFE_VQ_API_WH;

CREATE OR REPLACE PROCEDURE LIST_VERIFIED_QUERIES(
    SEMANTIC_VIEW_NAME VARCHAR    -- Fully qualified: DB.SCHEMA.VIEW
)
RETURNS TABLE (NAME VARCHAR, QUESTION VARCHAR, SQL_TEXT VARCHAR)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pyyaml')
HANDLER = 'list_verified_queries'
COMMENT = 'DEMO: List all verified queries in a semantic view (Expires: 2026-03-07)'
EXECUTE AS CALLER
AS
$$
import yaml
from snowflake.snowpark import Session
from snowflake.snowpark.types import StructType, StructField, StringType


def list_verified_queries(session: Session, semantic_view_name: str):
    # Read current YAML
    try:
        result = session.sql(
            f"SELECT SYSTEM$READ_YAML_FROM_SEMANTIC_VIEW('{semantic_view_name}')"
        ).collect()
        current_yaml = result[0][0]
    except Exception as e:
        schema = StructType([
            StructField("NAME", StringType()),
            StructField("QUESTION", StringType()),
            StructField("SQL_TEXT", StringType()),
        ])
        return session.create_dataframe(
            [("ERROR", str(e), "")], schema=schema
        )

    # Parse YAML and extract verified queries
    sv_spec = yaml.safe_load(current_yaml)
    verified_queries = sv_spec.get('verified_queries', [])

    # Build result rows
    rows = []
    for vq in verified_queries:
        rows.append((
            vq.get('name', ''),
            vq.get('question', ''),
            vq.get('sql', ''),
        ))

    # Return empty result set if no verified queries
    if not rows:
        rows = [("(none)", "No verified queries found", "")]

    schema = StructType([
        StructField("NAME", StringType()),
        StructField("QUESTION", StringType()),
        StructField("SQL_TEXT", StringType()),
    ])

    return session.create_dataframe(rows, schema=schema)
$$;
