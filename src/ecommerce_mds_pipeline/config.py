"""Runtime configuration, read from environment variables (12-factor style)."""

import os
from dataclasses import dataclass


def _required(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


@dataclass(frozen=True)
class SnowflakeConfig:
    account: str
    user: str
    private_key_file: str
    private_key_file_pwd: str | None
    role: str
    warehouse: str
    database: str
    schema: str

    @classmethod
    def from_env(cls) -> "SnowflakeConfig":
        # Defaults match the objects provisioned by Terraform (see terraform/).
        return cls(
            account=_required("SNOWFLAKE_ACCOUNT"),
            user=os.getenv("SNOWFLAKE_USER", "LOADER_USER"),
            private_key_file=_required("SNOWFLAKE_PRIVATE_KEY_FILE"),
            # Empty means "not set", so a blank line in .env doesn't reach the
            # connector as an empty passphrase.
            private_key_file_pwd=os.getenv("SNOWFLAKE_PRIVATE_KEY_FILE_PWD") or None,
            role=os.getenv("SNOWFLAKE_ROLE", "LOADER_ROLE"),
            warehouse=os.getenv("SNOWFLAKE_WAREHOUSE", "ECOMMERCE_WH"),
            database=os.getenv("SNOWFLAKE_DATABASE", "ECOMMERCE_DB"),
            schema=os.getenv("SNOWFLAKE_SCHEMA", "RAW"),
        )
