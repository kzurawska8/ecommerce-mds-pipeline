# --- Connection -------------------------------------------------------------

variable "snowflake_organization_name" {
  description = "Snowflake organization name (first part of <org>-<account> identifier)."
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name (second part of <org>-<account> identifier)."
  type        = string
}

variable "terraform_user" {
  description = "Service user Terraform authenticates as (created by bootstrap.sql)."
  type        = string
  default     = "TERRAFORM_SVC"
}

variable "terraform_private_key_path" {
  description = "Path to the Terraform service user's encrypted private key."
  type        = string
  default     = "../keys/terraform_svc_rsa_key.p8"
}

# --- Service user public keys ------------------------------------------------

variable "loader_public_key_path" {
  description = "Path to the ingestion service user's public key."
  type        = string
  default     = "../keys/loader_user_rsa_key.pub"
}

variable "dbt_public_key_path" {
  description = "Path to the dbt service user's public key."
  type        = string
  default     = "../keys/dbt_user_rsa_key.pub"
}

# --- Objects -----------------------------------------------------------------

variable "warehouse_name" {
  description = "Name of the compute warehouse used by ingestion and dbt."
  type        = string
  default     = "ECOMMERCE_WH"
}

variable "warehouse_size" {
  description = "Warehouse size. X-Small (1 credit/hour) is plenty for this project."
  type        = string
  default     = "XSMALL"
}

variable "warehouse_auto_suspend_seconds" {
  description = "Seconds of inactivity before the warehouse suspends (stops billing)."
  type        = number
  default     = 60
}

variable "database_name" {
  description = "Name of the project database."
  type        = string
  default     = "ECOMMERCE_DB"
}
