"""Entry point: extract all resources from DummyJSON, then load them into Snowflake."""

import argparse
import logging
import os
import uuid
from datetime import UTC, datetime

from ecommerce_mds_pipeline.config import SnowflakeConfig
from ecommerce_mds_pipeline.extract import build_session, fetch_all
from ecommerce_mds_pipeline.load import connect, load_records

RESOURCES = ("products", "users", "carts")

log = logging.getLogger("ecommerce_mds_pipeline")


def main() -> None:
    parser = argparse.ArgumentParser(description="Load DummyJSON data into Snowflake RAW.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Extract from the API only; skip connecting to Snowflake.",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(name)s - %(message)s",
    )

    loaded_at = datetime.now(UTC)
    batch_id = f"{loaded_at:%Y%m%dT%H%M%SZ}_{uuid.uuid4().hex[:8]}"
    log.info("Starting batch %s", batch_id)

    # Extract everything before touching Snowflake: if the API is down or
    # returns incomplete data, nothing is loaded and RAW stays consistent.
    session = build_session()
    data = {resource: fetch_all(session, resource) for resource in RESOURCES}

    if args.dry_run:
        log.info("Dry run - skipping load: %s", {r: len(v) for r, v in data.items()})
        return

    config = SnowflakeConfig.from_env()
    with connect(config) as conn:
        for resource, records in data.items():
            load_records(conn, resource, records, batch_id, loaded_at)

    log.info("Batch %s complete", batch_id)


if __name__ == "__main__":
    main()
