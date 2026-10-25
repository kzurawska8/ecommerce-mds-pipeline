# Privileges for functional roles. Granted by SECURITYADMIN (MANAGE GRANTS),
# while objects stay owned by SYSADMIN.

locals {
  all_roles = { for k, r in snowflake_account_role.this : k => r.name }
}

# --- Shared: every role can use the warehouse and see the database ------------

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  for_each = local.all_roles
  provider = snowflake.securityadmin

  account_role_name = each.value
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.ecommerce.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  for_each = local.all_roles
  provider = snowflake.securityadmin

  account_role_name = each.value
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.ecommerce.name
  }
}

# --- LOADER_ROLE: create and write raw tables ---------------------------------

resource "snowflake_grant_privileges_to_account_role" "loader_raw_schema" {
  provider = snowflake.securityadmin

  account_role_name = local.all_roles["LOADER_ROLE"]
  # CREATE STAGE / FILE FORMAT are needed for bulk loading (PUT + COPY INTO).
  privileges = ["USAGE", "CREATE TABLE", "CREATE STAGE", "CREATE FILE FORMAT"]
  on_schema {
    schema_name = snowflake_schema.raw.fully_qualified_name
  }
}

# --- TRANSFORMER_ROLE: read RAW, build its own schemas ------------------------

resource "snowflake_grant_privileges_to_account_role" "transformer_create_schema" {
  provider = snowflake.securityadmin

  account_role_name = local.all_roles["TRANSFORMER_ROLE"]
  privileges        = ["CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.ecommerce.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_schema" {
  provider = snowflake.securityadmin

  account_role_name = local.all_roles["TRANSFORMER_ROLE"]
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.raw.fully_qualified_name
  }
}

# Future grant: every table the loader creates in RAW is automatically
# readable by dbt - no manual GRANT after each new source table.
resource "snowflake_grant_privileges_to_account_role" "transformer_raw_future_tables" {
  provider = snowflake.securityadmin

  account_role_name = local.all_roles["TRANSFORMER_ROLE"]
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.raw.fully_qualified_name
    }
  }
}

# REPORTER_ROLE: no schema grants here on purpose. Marts schemas are created
# by dbt, so read access is granted by dbt itself via the `grants` config.
