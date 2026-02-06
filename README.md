# Verified Query API

![Expires](https://img.shields.io/badge/Expires-2026--03--07-orange)

> **Warning:** This demo expires on 2026-03-07. After expiration, deployment will fail.

Programmatic management of Cortex Analyst verified queries through stored procedures and the SQL API.

**Author:** SE Community
**Created:** 2026-02-05 | **Expires:** 2026-03-07 | **Status:** ACTIVE

## First Time Here?

1. **Deploy** - Copy `deploy_all.sql` into Snowsight, click "Run All"
2. **Test in Snowsight** - Open `sql/05_demo/01_demo_workflow.sql` and run the examples
3. **Test externally** - Use `tools/vq_manager.py` to manage queries from the command line
4. **Cleanup** - Run `teardown_all.sql` when done

## What This Demo Shows

Cortex Analyst uses verified queries to improve response accuracy. While Snowsight supports adding verified queries through the UI, there is no native `ALTER SEMANTIC VIEW ADD VERIFIED QUERY` SQL command.

This demo provides two integration paths:

### Path 1: Stored Procedures (Snowsight / SQL)

| Procedure | Description |
|-----------|-------------|
| `ADD_VERIFIED_QUERY` | Add or update a verified query in a semantic view |
| `LIST_VERIFIED_QUERIES` | List all verified queries in a semantic view |
| `REMOVE_VERIFIED_QUERY` | Remove a verified query by name |

### Path 2: External CLI (SQL API)

```bash
pip install -r requirements.txt
export SNOWFLAKE_ACCOUNT='myorg-myaccount'
export SNOWFLAKE_PAT='your-programmatic-access-token'

python tools/vq_manager.py list
python tools/vq_manager.py add monthly_revenue "What is total revenue by month?" "SELECT ..."
python tools/vq_manager.py bulk-load tools/verified_queries.json
python tools/vq_manager.py backup queries_backup.json
```

### How It Works

Both paths leverage two system functions:

- `SYSTEM$READ_YAML_FROM_SEMANTIC_VIEW` - Reads the current YAML specification
- `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML` - Creates/replaces a semantic view from YAML (with COPY GRANTS)

Agents reference semantic views by name, not by internal ID. When a semantic view is replaced, existing agent configurations remain valid.

## Prerequisites

- Snowflake account with Cortex Analyst access
- `SYSADMIN` role (or equivalent privileges)
- `SFE_GIT_API_INTEGRATION` configured (for Git-based deployment)

## Project Structure

```
agent-vq-api/
├── README.md
├── deploy_all.sql
├── teardown_all.sql
├── requirements.txt                   # Python dependencies for CLI tool
├── diagrams/
│   └── data-flow.md
├── sql/
│   ├── 01_setup/
│   │   └── 01_create_schema.sql
│   ├── 02_tables/
│   │   └── 01_sample_data.sql
│   ├── 03_semantic_view/
│   │   └── 01_create_semantic_view.sql
│   ├── 04_procedures/
│   │   ├── 01_add_verified_query.sql
│   │   ├── 02_list_verified_queries.sql
│   │   └── 03_remove_verified_query.sql
│   └── 05_demo/
│       └── 01_demo_workflow.sql
├── tools/
│   ├── vq_manager.py                  # External CLI via SQL API
│   └── verified_queries.json          # Sample queries for bulk loading
└── docs/
    ├── 01-GETTING-STARTED.md
    └── 02-SQL-API-INTEGRATION.md
```

## Best Practices

- **Use Logical Table Names:** In verified query SQL, reference logical tables with double-underscore prefix (e.g., `__ORDERS` not `SNOWFLAKE_EXAMPLE.VQ_API.RAW_ORDERS`)
- **Unique Query Names:** Use descriptive, unique names for each verified query
- **Test Queries First:** Validate SQL syntax and results before adding as a verified query
- **Backup Before Bulk Changes:** Use `SYSTEM$READ_YAML_FROM_SEMANTIC_VIEW` to backup YAML before bulk modifications
