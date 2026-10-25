resource "snowflake_database" "ecommerce" {
  name    = var.database_name
  comment = "E-commerce analytics database. Managed by Terraform."
}

# Landing zone for raw API data. Only RAW is managed here: the STAGING and
# MARTS schemas are created and owned by dbt (TRANSFORMER_ROLE has
# CREATE SCHEMA on the database), so dev/prod targets can build isolated schemas.
#
# Managed access: the loader owns the tables it creates, but cannot grant
# access to them - only the schema owner / SECURITYADMIN can. Access to raw
# data stays centrally controlled.
resource "snowflake_schema" "raw" {
  database            = snowflake_database.ecommerce.name
  name                = "RAW"
  with_managed_access = "true"
  comment             = "Raw, append-only data landed 1:1 from the source API. Managed by Terraform."
}
