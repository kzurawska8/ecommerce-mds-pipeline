import json
from datetime import UTC, datetime

import pytest

from ecommerce_mds_pipeline.load import load_records, to_ndjson

LOADED_AT = datetime(2026, 1, 1, 6, 0, tzinfo=UTC)
BATCH_ID = "20260101T060000Z_abcd1234"


class FakeCursor:
    """Records executed SQL and returns a canned COPY INTO result."""

    def __init__(self, rows_loaded):
        self.statements = []
        self.description = [("file",), ("status",), ("rows_loaded",)]
        self._rows_loaded = rows_loaded

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def execute(self, sql):
        self.statements.append(" ".join(sql.split()))

    def fetchall(self):
        return [("products.json.gz", "LOADED", self._rows_loaded)]


class FakeConnection:
    def __init__(self, cursor):
        self._cursor = cursor

    def cursor(self):
        return self._cursor


def test_to_ndjson_wraps_each_record_in_metadata_envelope():
    lines = to_ndjson([{"id": 1}, {"id": 2}], "products", BATCH_ID, LOADED_AT).splitlines()

    assert len(lines) == 2
    assert json.loads(lines[0]) == {
        "payload": {"id": 1},
        "_source": "dummyjson/products",
        "_batch_id": BATCH_ID,
        "_loaded_at": "2026-01-01T06:00:00+00:00",
    }


def test_load_records_creates_table_stages_and_copies():
    cursor = FakeCursor(rows_loaded=2)

    loaded = load_records(
        FakeConnection(cursor), "products", [{"id": 1}, {"id": 2}], BATCH_ID, LOADED_AT
    )

    assert loaded == 2
    create, put, copy = cursor.statements
    assert create.startswith("CREATE TABLE IF NOT EXISTS PRODUCTS")
    assert put.startswith("PUT 'file://") and f"@%PRODUCTS/{BATCH_ID}/" in put
    assert copy.startswith("COPY INTO PRODUCTS") and "ON_ERROR = ABORT_STATEMENT" in copy


def test_load_records_fails_on_row_count_mismatch():
    cursor = FakeCursor(rows_loaded=1)

    with pytest.raises(RuntimeError, match="expected 2 rows, COPY loaded 1"):
        load_records(
            FakeConnection(cursor), "products", [{"id": 1}, {"id": 2}], BATCH_ID, LOADED_AT
        )
