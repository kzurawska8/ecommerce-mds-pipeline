# Functional roles - one per workload, least privilege.
#
#   LOADER_ROLE      -> writes raw data into RAW            (ingestion)
#   TRANSFORMER_ROLE -> reads RAW, builds staging/marts     (dbt)
#   REPORTER_ROLE    -> reads marts only                    (BI / analysts)

locals {
  roles = {
    LOADER_ROLE      = "Ingestion: write access to RAW schema."
    TRANSFORMER_ROLE = "dbt: read RAW, create and own staging/marts schemas."
    REPORTER_ROLE    = "Analytics consumers: read-only access to marts (granted by dbt)."
  }
}

resource "snowflake_account_role" "this" {
  for_each = local.roles
  provider = snowflake.securityadmin

  name    = each.key
  comment = each.value
}

# Snowflake best practice: attach every custom role to SYSADMIN so admins can
# manage the objects these roles create (avoids orphaned object ownership).
resource "snowflake_grant_account_role" "to_sysadmin" {
  for_each = snowflake_account_role.this
  provider = snowflake.securityadmin

  role_name        = each.value.name
  parent_role_name = "SYSADMIN"
}
