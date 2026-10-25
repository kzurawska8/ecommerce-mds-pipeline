import pytest

from ecommerce_mds_pipeline.extract import fetch_all


class FakeResponse:
    def __init__(self, body):
        self._body = body

    def raise_for_status(self):
        pass

    def json(self):
        return self._body


class FakeSession:
    """Serves `items` from memory the way DummyJSON paginates with limit/skip."""

    def __init__(self, resource, items, reported_total=None):
        self.resource = resource
        self.items = items
        self.reported_total = len(items) if reported_total is None else reported_total
        self.calls = []

    def get(self, url, params, timeout):
        self.calls.append(params)
        page = self.items[params["skip"] : params["skip"] + params["limit"]]
        return FakeResponse({self.resource: page, "total": self.reported_total})


def test_fetch_all_paginates_until_total():
    items = [{"id": i} for i in range(1, 251)]
    session = FakeSession("products", items)

    records = fetch_all(session, "products", page_size=100)

    assert records == items
    assert [c["skip"] for c in session.calls] == [0, 100, 200]


def test_fetch_all_raises_when_api_returns_fewer_records_than_total():
    session = FakeSession("carts", [{"id": 1}, {"id": 2}], reported_total=5)

    with pytest.raises(ValueError, match="API reported 5 records, fetched 2"):
        fetch_all(session, "carts", page_size=100)


def test_fetch_all_drops_excluded_fields():
    session = FakeSession("users", [{"id": 1, "username": "emilys", "password": "secret"}])

    records = fetch_all(session, "users")

    assert records == [{"id": 1, "username": "emilys"}]
