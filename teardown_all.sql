/*==============================================================================
TEARDOWN ALL - Verified Query API
WARNING: This will DELETE all demo objects. Cannot be undone.
==============================================================================*/

USE ROLE SYSADMIN;

-- Drop semantic view
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS;

-- Drop project schema (CASCADE removes all objects including procedures)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.VQ_API CASCADE;

-- Drop project warehouse
DROP WAREHOUSE IF EXISTS SFE_VQ_API_WH;

-- Drop Git repository
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO;

-- PROTECTED - NEVER DROP:
-- SNOWFLAKE_EXAMPLE database
-- SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema
-- SNOWFLAKE_EXAMPLE.TOOLS schema
-- SFE_GIT_API_INTEGRATION

SELECT 'Teardown complete!' AS status;
