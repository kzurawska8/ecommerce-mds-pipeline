"""Extract: paginated reads from the DummyJSON REST API."""

import logging
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

log = logging.getLogger(__name__)

BASE_URL = "https://dummyjson.com"
PAGE_SIZE = 100
TIMEOUT_SECONDS = 30

# Fields never landed in the warehouse. DummyJSON users carry (fake) plaintext
# passwords - credentials must not be persisted, not even in RAW.
EXCLUDED_FIELDS: dict[str, set[str]] = {"users": {"password"}}


def build_session() -> requests.Session:
    """HTTP session with retries and exponential backoff for transient errors."""
    retry = Retry(
        total=5,
        backoff_factor=1,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=("GET",),
    )
    session = requests.Session()
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers["User-Agent"] = "ecommerce-mds-pipeline"
    return session


def fetch_all(
    session: requests.Session, resource: str, page_size: int = PAGE_SIZE
) -> list[dict[str, Any]]:
    """Fetch every record of a resource, page by page, and verify completeness."""
    records: list[dict[str, Any]] = []
    total = None
    while total is None or len(records) < total:
        response = session.get(
            f"{BASE_URL}/{resource}",
            params={"limit": page_size, "skip": len(records)},
            timeout=TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        body = response.json()
        page = body[resource]
        total = body["total"]
        if not page:
            break
        records.extend(page)

    if len(records) != total:
        raise ValueError(f"{resource}: API reported {total} records, fetched {len(records)}")

    log.info("Extracted %d %s", len(records), resource)
    excluded = EXCLUDED_FIELDS.get(resource, set())
    return [{k: v for k, v in record.items() if k not in excluded} for record in records]
