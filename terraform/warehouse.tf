resource "snowflake_warehouse" "ecommerce" {
  name                = var.warehouse_name
  warehouse_size      = var.warehouse_size
  auto_suspend        = var.warehouse_auto_suspend_seconds
  auto_resume         = "true"
  initially_suspended = true

  # Guardrail: kill any single query running longer than 1 hour.
  statement_timeout_in_seconds = 3600

  comment = "Compute for ingestion and dbt transformations. Managed by Terraform."
}
