#!/usr/bin/env python3
"""
Verified Query Manager - External API Client

Manages Cortex Analyst verified queries via the Snowflake SQL API (REST).
Demonstrates how any external system can programmatically manage verified
queries without a direct Snowflake session.

Usage:
    python vq_manager.py list
    python vq_manager.py add <name> <question> <sql>
    python vq_manager.py remove <name>
    python vq_manager.py backup [output_file]
    python vq_manager.py bulk-load <json_file>

Environment Variables (required):
    SNOWFLAKE_ACCOUNT   - Account identifier (e.g. myorg-myaccount)
    SNOWFLAKE_PAT       - Programmatic access token

Environment Variables (optional):
    SNOWFLAKE_WAREHOUSE - Warehouse (default: SFE_VQ_API_WH)
    SNOWFLAKE_ROLE      - Role (default: SYSADMIN)
    SNOWFLAKE_SV        - Semantic view (default: SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS)

Author: SE Community
"""

import argparse
import json
import os
import sys
import time

import requests


# ---------------------------------------------------------------------------
# Configuration from environment
# ---------------------------------------------------------------------------

def get_config():
    account = os.environ.get("SNOWFLAKE_ACCOUNT")
    token = os.environ.get("SNOWFLAKE_PAT")

    if not account or not token:
        print("Error: SNOWFLAKE_ACCOUNT and SNOWFLAKE_PAT must be set.")
        print("")
        print("  export SNOWFLAKE_ACCOUNT='myorg-myaccount'")
        print("  export SNOWFLAKE_PAT='your-programmatic-access-token'")
        sys.exit(1)

    return {
        "account": account,
        "token": token,
        "warehouse": os.environ.get("SNOWFLAKE_WAREHOUSE", "SFE_VQ_API_WH"),
        "role": os.environ.get("SNOWFLAKE_ROLE", "SYSADMIN"),
        "semantic_view": os.environ.get(
            "SNOWFLAKE_SV",
            "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS",
        ),
    }


# ---------------------------------------------------------------------------
# SQL API Client
# ---------------------------------------------------------------------------

class SqlApiClient:
    """Thin wrapper around the Snowflake SQL API v2."""

    def __init__(self, account: str, token: str, warehouse: str, role: str):
        self.base_url = f"https://{account}.snowflakecomputing.com"
        self.endpoint = f"{self.base_url}/api/v2/statements"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
        }
        self.warehouse = warehouse
        self.role = role

    def execute(self, sql: str, poll_timeout: int = 60) -> dict:
        """Submit a SQL statement and poll until completion."""
        payload = {
            "statement": sql,
            "warehouse": self.warehouse,
            "role": self.role,
            "database": "SNOWFLAKE_EXAMPLE",
            "schema": "VQ_API",
            "timeout": poll_timeout,
        }

        resp = requests.post(
            self.endpoint,
            headers=self.headers,
            json=payload,
            timeout=30,
        )
        resp.raise_for_status()
        result = resp.json()

        # Poll for async results if needed
        handle = result.get("statementHandle")
        status = result.get("statementStatusUrl")

        while result.get("code") == "333334":  # async pending
            time.sleep(1)
            resp = requests.get(
                f"{self.endpoint}/{handle}",
                headers=self.headers,
                timeout=30,
            )
            resp.raise_for_status()
            result = resp.json()

        return result

    def parse_rows(self, result: dict) -> list[dict]:
        """Parse SQL API result into a list of dicts."""
        meta = result.get("resultSetMetaData", {})
        columns = [col["name"] for col in meta.get("rowType", [])]
        data = result.get("data", [])
        return [dict(zip(columns, row)) for row in data]


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_list(client: SqlApiClient, sv: str):
    """List all verified queries in the semantic view."""
    sql = f"CALL LIST_VERIFIED_QUERIES('{sv}')"
    result = client.execute(sql)
    rows = client.parse_rows(result)

    if not rows:
        print("No verified queries found.")
        return

    # Print formatted table
    name_w = max(len(r.get("NAME", "")) for r in rows)
    question_w = max(len(r.get("QUESTION", "")) for r in rows)
    name_w = max(name_w, 4)
    question_w = max(question_w, 8)

    header = f"{'NAME':<{name_w}}  {'QUESTION':<{question_w}}  SQL_TEXT"
    print(header)
    print("-" * len(header))

    for row in rows:
        name = row.get("NAME", "")
        question = row.get("QUESTION", "")
        sql_text = row.get("SQL_TEXT", "")
        # Truncate SQL for display
        sql_display = sql_text[:80] + "..." if len(sql_text) > 80 else sql_text
        print(f"{name:<{name_w}}  {question:<{question_w}}  {sql_display}")


def cmd_add(client: SqlApiClient, sv: str, name: str, question: str, sql_query: str):
    """Add or update a verified query."""
    # Escape single quotes for SQL string
    name_esc = name.replace("'", "''")
    question_esc = question.replace("'", "''")
    sql_esc = sql_query.replace("'", "''")

    sql = (
        f"CALL ADD_VERIFIED_QUERY("
        f"'{sv}', '{name_esc}', '{question_esc}', '{sql_esc}')"
    )
    result = client.execute(sql)
    rows = client.parse_rows(result)

    if rows:
        print(rows[0].get("ADD_VERIFIED_QUERY", "Done"))
    else:
        print("Done")


def cmd_remove(client: SqlApiClient, sv: str, name: str):
    """Remove a verified query by name."""
    name_esc = name.replace("'", "''")
    sql = f"CALL REMOVE_VERIFIED_QUERY('{sv}', '{name_esc}')"
    result = client.execute(sql)
    rows = client.parse_rows(result)

    if rows:
        print(rows[0].get("REMOVE_VERIFIED_QUERY", "Done"))
    else:
        print("Done")


def cmd_backup(client: SqlApiClient, sv: str, output_file: str | None):
    """Backup verified queries to a JSON file."""
    sql = f"CALL LIST_VERIFIED_QUERIES('{sv}')"
    result = client.execute(sql)
    rows = client.parse_rows(result)

    queries = []
    for row in rows:
        name = row.get("NAME", "")
        if name and name != "(none)":
            queries.append({
                "name": name,
                "question": row.get("QUESTION", ""),
                "sql": row.get("SQL_TEXT", ""),
            })

    output = json.dumps(queries, indent=2)

    if output_file:
        with open(output_file, "w") as f:
            f.write(output)
        print(f"Backed up {len(queries)} verified queries to {output_file}")
    else:
        print(output)


def cmd_bulk_load(client: SqlApiClient, sv: str, json_file: str):
    """Load verified queries from a JSON file."""
    with open(json_file) as f:
        queries = json.load(f)

    if not isinstance(queries, list):
        print("Error: JSON file must contain an array of query objects")
        sys.exit(1)

    print(f"Loading {len(queries)} verified queries...")
    for i, query in enumerate(queries, 1):
        name = query.get("name", "")
        question = query.get("question", "")
        sql_query = query.get("sql", "")

        if not all([name, question, sql_query]):
            print(f"  [{i}] SKIP: Missing required fields in entry")
            continue

        cmd_add(client, sv, name, question, sql_query)
        print(f"  [{i}] {name}")

    print(f"\nLoaded {len(queries)} verified queries.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Manage Cortex Analyst verified queries via the Snowflake SQL API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
examples:
  %(prog)s list
  %(prog)s add monthly_revenue "What is the total revenue by month?" "SELECT ..."
  %(prog)s remove monthly_revenue
  %(prog)s backup queries_backup.json
  %(prog)s bulk-load verified_queries.json

environment:
  SNOWFLAKE_ACCOUNT   Account identifier (required)
  SNOWFLAKE_PAT       Programmatic access token (required)
  SNOWFLAKE_WAREHOUSE Warehouse (default: SFE_VQ_API_WH)
  SNOWFLAKE_ROLE      Role (default: SYSADMIN)
  SNOWFLAKE_SV        Semantic view (default: SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_VQ_API_ORDERS)
        """,
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # list
    subparsers.add_parser("list", help="List all verified queries")

    # add
    add_parser = subparsers.add_parser("add", help="Add or update a verified query")
    add_parser.add_argument("name", help="Unique query name")
    add_parser.add_argument("question", help="Natural language question")
    add_parser.add_argument("sql", help="SQL using __tablename references")

    # remove
    rm_parser = subparsers.add_parser("remove", help="Remove a verified query")
    rm_parser.add_argument("name", help="Name of query to remove")

    # backup
    bk_parser = subparsers.add_parser("backup", help="Backup queries to JSON")
    bk_parser.add_argument("output", nargs="?", help="Output file (prints to stdout if omitted)")

    # bulk-load
    bl_parser = subparsers.add_parser("bulk-load", help="Load queries from JSON file")
    bl_parser.add_argument("json_file", help="Path to JSON file with query definitions")

    args = parser.parse_args()

    # Build client
    config = get_config()
    client = SqlApiClient(
        account=config["account"],
        token=config["token"],
        warehouse=config["warehouse"],
        role=config["role"],
    )
    sv = config["semantic_view"]

    # Dispatch
    if args.command == "list":
        cmd_list(client, sv)
    elif args.command == "add":
        cmd_add(client, sv, args.name, args.question, args.sql)
    elif args.command == "remove":
        cmd_remove(client, sv, args.name)
    elif args.command == "backup":
        cmd_backup(client, sv, args.output)
    elif args.command == "bulk-load":
        cmd_bulk_load(client, sv, args.json_file)


if __name__ == "__main__":
    main()
