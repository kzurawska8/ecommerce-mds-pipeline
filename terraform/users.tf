# Service users (TYPE = SERVICE): no password, no MFA, key-pair auth only.

locals {
  # Snowflake expects the public key body on one line, without PEM header/footer.
  strip_pem = "/-----[A-Z ]+-----|\\s/"

  service_users = {
    LOADER_USER = {
      role        = snowflake_account_role.this["LOADER_ROLE"].name
      public_key  = replace(file(var.loader_public_key_path), local.strip_pem, "")
      default_ns  = "${snowflake_database.ecommerce.name}.${snowflake_schema.raw.name}"
      description = "Python ingestion job (Docker / GitHub Actions)."
    }
    DBT_USER = {
      role        = snowflake_account_role.this["TRANSFORMER_ROLE"].name
      public_key  = replace(file(var.dbt_public_key_path), local.strip_pem, "")
      default_ns  = snowflake_database.ecommerce.name
      description = "dbt transformations (local dev + GitHub Actions)."
    }
  }
}

resource "snowflake_service_user" "this" {
  for_each = local.service_users
  provider = snowflake.securityadmin

  name           = each.key
  rsa_public_key = each.value.public_key

  default_role      = each.value.role
  default_warehouse = snowflake_warehouse.ecommerce.name
  default_namespace = each.value.default_ns
  # Only the default role is active in a session - no implicit extra privileges.
  default_secondary_roles_option = "NONE"

  comment = each.value.description
}

resource "snowflake_grant_account_role" "to_user" {
  for_each = local.service_users
  provider = snowflake.securityadmin

  role_name = each.value.role
  user_name = snowflake_service_user.this[each.key].name
}
