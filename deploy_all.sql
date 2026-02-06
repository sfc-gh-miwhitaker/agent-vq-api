/*==============================================================================
DEPLOY ALL - Verified Query API
Author: SE Community | Expires: 2026-03-07
INSTRUCTIONS: Open in Snowsight -> Click "Run All"
PREREQUISITE: SFE_GIT_API_INTEGRATION must exist (shared infrastructure)
==============================================================================*/

-- 1. SSOT: Expiration date - change ONLY here, then run: sync-expiration
SET DEMO_EXPIRES = '2026-03-07';

-- 2. Expiration check
DECLARE
  demo_expired EXCEPTION (-20001, 'DEMO EXPIRED - contact owner');
BEGIN
  IF (CURRENT_DATE() > $DEMO_EXPIRES::DATE) THEN
    RAISE demo_expired;
  END IF;
END;

-- 3. Fetch latest from Git
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.TOOLS;

CREATE GIT REPOSITORY IF NOT EXISTS SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO
  API_INTEGRATION = SFE_GIT_API_INTEGRATION
  ORIGIN = 'https://github.com/sfc-gh-miwhitaker/agent-vq-api.git';

ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO FETCH;

-- 4. Execute scripts in order
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO/branches/main/sql/01_setup/01_create_schema.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO/branches/main/sql/02_tables/01_sample_data.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO/branches/main/sql/03_semantic_view/01_create_semantic_view.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO/branches/main/sql/04_procedures/01_add_verified_query.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO/branches/main/sql/04_procedures/02_list_verified_queries.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.TOOLS.SFE_VQ_API_REPO/branches/main/sql/04_procedures/03_remove_verified_query.sql';

-- 5. Final summary (ONLY visible result in Run All)
SELECT 'Deployment complete!' AS status,
       'SNOWFLAKE_EXAMPLE.VQ_API' AS schema_deployed,
       'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS' AS semantic_view,
       CURRENT_TIMESTAMP() AS completed_at;
