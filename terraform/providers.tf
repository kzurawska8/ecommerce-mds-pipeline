# Two provider configurations, same service user, different roles.
# This follows Snowflake's recommended separation of duties:
#   - SYSADMIN creates and owns objects (warehouse, database, schemas)
#   - SECURITYADMIN creates roles/users and manages grants
# The private key passphrase is read from SNOWFLAKE_PRIVATE_KEY_PASSPHRASE.

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.terraform_user
  role              = "SYSADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.terraform_private_key_path)
}

provider "snowflake" {
  alias = "securityadmin"

  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.terraform_user
  role              = "SECURITYADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.terraform_private_key_path)
}
