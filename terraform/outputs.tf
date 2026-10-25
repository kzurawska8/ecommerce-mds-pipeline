output "warehouse_name" {
  value = snowflake_warehouse.ecommerce.name
}

output "database_name" {
  value = snowflake_database.ecommerce.name
}

output "raw_schema" {
  value = snowflake_schema.raw.fully_qualified_name
}

output "service_users" {
  description = "Service user -> default role. Use these in the loader and dbt profiles."
  value       = { for k, v in local.service_users : k => v.role }
}
