-- =============================================================================
-- One-time bootstrap, run manually in a Snowsight worksheet as your own
-- (human, MFA-protected) ACCOUNTADMIN user.
--
-- Why this is not in Terraform:
--   1. Chicken-and-egg: Terraform needs a user to authenticate as before it
--      can manage anything.
--   2. Resource monitors can only be created/assigned by ACCOUNTADMIN. Keeping
--      the cost guardrail here means the Terraform service user never needs
--      ACCOUNTADMIN - automation runs with SYSADMIN + SECURITYADMIN only.
--
-- Before running: generate the key with ./scripts/generate_keypair.sh terraform_svc
-- and paste the public key body below.
-- =============================================================================

-- 1. Service user for Terraform (key-pair auth only, no password)
USE ROLE USERADMIN;

CREATE USER IF NOT EXISTS TERRAFORM_SVC
    TYPE = SERVICE
    RSA_PUBLIC_KEY = '<PASTE_TERRAFORM_SVC_PUBLIC_KEY_BODY_HERE>'
    DEFAULT_ROLE = SYSADMIN
    DEFAULT_SECONDARY_ROLES = ()
    COMMENT = 'Terraform service user for ecommerce-mds-pipeline';

-- 2. SYSADMIN creates and owns objects (warehouse, database, schemas);
--    SECURITYADMIN creates roles/users and manages grants.
USE ROLE SECURITYADMIN;

GRANT ROLE SYSADMIN      TO USER TERRAFORM_SVC;
GRANT ROLE SECURITYADMIN TO USER TERRAFORM_SVC;

-- 3. Cost guardrail: account-level resource monitor. It covers every
--    warehouse in the account (including ones created later by Terraform),
--    so a runaway query can't drain the trial credits.
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR IF NOT EXISTS ACCOUNT_MONTHLY_BUDGET
    WITH CREDIT_QUOTA = 10
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 50  PERCENT DO NOTIFY
        ON 80  PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND
        ON 110 PERCENT DO SUSPEND_IMMEDIATE;

ALTER ACCOUNT SET RESOURCE_MONITOR = ACCOUNT_MONTHLY_BUDGET;

-- Verify
SHOW USERS LIKE 'TERRAFORM_SVC';
SHOW GRANTS TO USER TERRAFORM_SVC;
SHOW RESOURCE MONITORS;
