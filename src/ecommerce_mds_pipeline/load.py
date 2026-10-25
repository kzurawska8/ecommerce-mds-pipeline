"""Load: land raw JSON records in Snowflake via table stage + COPY INTO.

Each resource gets an append-only table in RAW:

    PAYLOAD     VARIANT       the API record, untouched (schema-on-read)
    _SOURCE     VARCHAR       where the record came from
    _BATCH_ID   VARCHAR       identifies the pipeline run
    _LOADED_AT  TIMESTAMP_TZ  when the run started

Every run appends a full snapshot; dbt staging picks the latest version of
each record. Nothing is ever updated or deleted in RAW, so history is kept and
any downstream model can be rebuilt from it.
"""

import json
import logging
import tempfile
from collections.abc import Iterable
from datetime import datetime
from pathlib import Path
from typing import Any

import snowflake.connector
from snowflake.connector import SnowflakeConnection

from ecommerce_mds_pipeline.config import SnowflakeConfig

log = logging.getLogger(__name__)

SOURCE_SYSTEM = "dummyjson"

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS {table} (
    PAYLOAD     VARIANT       NOT NULL,
    _SOURCE     VARCHAR       NOT NULL,
    _BATCH_ID   VARCHAR       NOT NULL,
    _LOADED_AT  TIMESTAMP_TZ  NOT NULL
)
COMMENT = 'Raw {resource} from DummyJSON API. Append-only, loaded by ecommerce-mds-pipeline.'
"""

# ON_ERROR = ABORT_STATEMENT: a single bad record fails the whole file, so a
# table never ends up with a partial batch. PURGE removes staged files after load.
COPY_SQL = """
COPY INTO {table} (PAYLOAD, _SOURCE, _BATCH_ID, _LOADED_AT)
FROM (
    SELECT
        $1:payload,
        $1:_source::VARCHAR,
        $1:_batch_id::VARCHAR,
        $1:_loaded_at::TIMESTAMP_TZ
    FROM @%{table}/{batch_id}/
)
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = ABORT_STATEMENT
PURGE = TRUE
"""


def connect(config: SnowflakeConfig) -> SnowflakeConnection:
    return snowflake.connector.connect(
        account=config.account,
        user=config.user,
        authenticator="SNOWFLAKE_JWT",
        private_key_file=config.private_key_file,
        private_key_file_pwd=config.private_key_file_pwd,
        role=config.role,
        warehouse=config.warehouse,
        database=config.database,
        schema=config.schema,
        application="ecommerce-mds-pipeline",
        query_tag="ecommerce-mds-pipeline:ingestion",
    )


def to_ndjson(
    records: Iterable[dict[str, Any]], resource: str, batch_id: str, loaded_at: datetime
) -> str:
    """Wrap each record in a metadata envelope, one JSON document per line."""
    lines = (
        json.dumps(
            {
                "payload": record,
                "_source": f"{SOURCE_SYSTEM}/{resource}",
                "_batch_id": batch_id,
                "_loaded_at": loaded_at.isoformat(),
            }
        )
        for record in records
    )
    return "\n".join(lines) + "\n"


def load_records(
    conn: SnowflakeConnection,
    resource: str,
    records: list[dict[str, Any]],
    batch_id: str,
    loaded_at: datetime,
) -> int:
    """Stage records as NDJSON and bulk-load them. Returns the number of rows loaded."""
    # Identifiers can't be bind parameters; resource names come from a fixed
    # allowlist in cli.RESOURCES, never from user input.
    table = resource.upper()

    with tempfile.TemporaryDirectory() as tmp_dir, conn.cursor() as cur:
        file_path = Path(tmp_dir) / f"{resource}.json"
        file_path.write_text(to_ndjson(records, resource, batch_id, loaded_at))

        cur.execute(CREATE_TABLE_SQL.format(table=table, resource=resource))
        cur.execute(
            f"PUT 'file://{file_path.as_posix()}' @%{table}/{batch_id}/ "
            "AUTO_COMPRESS = TRUE OVERWRITE = TRUE"
        )
        cur.execute(COPY_SQL.format(table=table, batch_id=batch_id))

        columns = [col[0].lower() for col in cur.description]
        results = [dict(zip(columns, row, strict=True)) for row in cur.fetchall()]

    rows_loaded = sum(int(r.get("rows_loaded") or 0) for r in results)
    if rows_loaded != len(records):
        raise RuntimeError(
            f"{table}: expected {len(records)} rows, COPY loaded {rows_loaded} ({results})"
        )

    log.info("Loaded %d rows into %s (batch %s)", rows_loaded, table, batch_id)
    return rows_loaded
