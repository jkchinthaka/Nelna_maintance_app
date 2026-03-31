"""Integration tests for the Inventory REST API.

These tests use httpx.AsyncClient with an ASGI transport, backed by an in-memory
SQLite DB and overridden FastAPI dependencies (auth + DB session).

The test_client fixture is defined in tests/conftest.py and wires admin auth
by default.  Where a non-admin context is needed, the dependency override is
swapped inline.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inventory import Product, ProductCategory
from tests.conftest import make_branch_user

pytestmark = pytest.mark.asyncio

BASE = "/api/v1/inventory"


# ---------------------------------------------------------------------------
# Helpers re-exported from conftest indirectly via fixture chain
# ---------------------------------------------------------------------------

async def _create_category_via_api(client: AsyncClient, name: str = "Test Cat") -> dict:
    res = await client.post(f"{BASE}/categories", json={"name": name, "description": "d"})
    assert res.status_code == 201, res.text
    return res.json()


async def _create_product_via_api(client: AsyncClient, sku: str, branch_id: int, category_id: int) -> dict:
    body = {
        "name": f"Widget {sku}",
        "sku": sku,
        "branch_id": branch_id,
        "category_id": category_id,
        "unit_price": "9.99",
        "current_stock": "100",
        "reorder_level": "20",
        "unit_of_measure": "pcs",
    }
    res = await client.post(f"{BASE}/products", json=body)
    assert res.status_code == 201, res.text
    return res.json()


# ===========================================================================
# CATEGORY endpoints
# ===========================================================================

class TestCategoryEndpoints:
    async def test_list_categories_returns_200(self, test_client: AsyncClient):
        res = await test_client.get(f"{BASE}/categories")
        assert res.status_code == 200
        assert isinstance(res.json(), list)

    async def test_create_category_returns_201(self, test_client: AsyncClient):
        res = await test_client.post(
            f"{BASE}/categories",
            json={"name": "Lubricants", "description": "All oils"},
        )
        assert res.status_code == 201
        data = res.json()
        assert data["name"] == "Lubricants"
        assert "id" in data

    async def test_create_duplicate_category_returns_409(self, test_client: AsyncClient):
        await test_client.post(f"{BASE}/categories", json={"name": "Dup409"})
        res = await test_client.post(f"{BASE}/categories", json={"name": "Dup409"})
        assert res.status_code == 409

    async def test_update_category_returns_200(self, test_client: AsyncClient):
        cat = await _create_category_via_api(test_client, name="UpdateMe")
        res = await test_client.put(
            f"{BASE}/categories/{cat['id']}",
            json={"description": "Updated desc"},
        )
        assert res.status_code == 200
        assert res.json()["description"] == "Updated desc"

    async def test_update_nonexistent_category_returns_404(self, test_client: AsyncClient):
        res = await test_client.put(f"{BASE}/categories/999999", json={"name": "ghost"})
        assert res.status_code == 404


# ===========================================================================
# PRODUCT endpoints
# ===========================================================================

class TestProductEndpoints:
    async def test_list_products_returns_paginated_response(self, test_client: AsyncClient):
        res = await test_client.get(f"{BASE}/products")
        assert res.status_code == 200
        data = res.json()
        assert "products" in data
        assert "pagination" in data

    async def test_create_product_returns_201(self, test_client: AsyncClient):
        cat = await _create_category_via_api(test_client, name="Create Cat")
        product = await _create_product_via_api(test_client, "CREATE-001", branch_id=1, category_id=cat["id"])
        assert product["sku"] == "CREATE-001"
        assert product["id"] is not None

    async def test_create_duplicate_sku_same_branch_returns_409(self, test_client: AsyncClient):
        cat = await _create_category_via_api(test_client, name="Dup SKU Cat")
        await _create_product_via_api(test_client, "DUP-SKU-001", branch_id=1, category_id=cat["id"])
        res = await test_client.post(
            f"{BASE}/products",
            json={
                "name": "Duplicate",
                "sku": "DUP-SKU-001",
                "branch_id": 1,
                "category_id": cat["id"],
                "unit_price": "5.00",
                "current_stock": "10",
                "reorder_level": "2",
                "unit_of_measure": "pcs",
            },
        )
        assert res.status_code == 409

    async def test_get_product_by_id_returns_200(self, test_client: AsyncClient):
        cat = await _create_category_via_api(test_client, name="Get Cat")
        product = await _create_product_via_api(test_client, "GET-001", branch_id=1, category_id=cat["id"])
        res = await test_client.get(f"{BASE}/products/{product['id']}")
        assert res.status_code == 200
        assert res.json()["id"] == product["id"]

    async def test_get_nonexistent_product_returns_404(self, test_client: AsyncClient):
        res = await test_client.get(f"{BASE}/products/999999")
        assert res.status_code == 404

    async def test_update_product_returns_200(self, test_client: AsyncClient):
        cat = await _create_category_via_api(test_client, name="Upd Cat")
        product = await _create_product_via_api(test_client, "UPD-001", branch_id=1, category_id=cat["id"])
        res = await test_client.put(
            f"{BASE}/products/{product['id']}",
            json={"name": "Updated Name"},
        )
        assert res.status_code == 200
        assert res.json()["name"] == "Updated Name"

    async def test_delete_product_returns_204(self, test_client: AsyncClient):
        cat = await _create_category_via_api(test_client, name="Del Cat")
        product = await _create_product_via_api(test_client, "DEL-API-001", branch_id=1, category_id=cat["id"])
        res = await test_client.delete(f"{BASE}/products/{product['id']}")
        assert res.status_code == 204
        # Confirm 404 on subsequent GET
        get_res = await test_client.get(f"{BASE}/products/{product['id']}")
        assert get_res.status_code == 404

    async def test_low_stock_endpoint_returns_list(self, test_client: AsyncClient):
        res = await test_client.get(f"{BASE}/products/low-stock")
        assert res.status_code == 200
        assert isinstance(res.json(), list)


# ===========================================================================
# STOCK MOVEMENT endpoints
# ===========================================================================

class TestStockEndpoints:
    async def _setup_product(self, client: AsyncClient, sku: str, stock: str = "100") -> dict:
        cat = await _create_category_via_api(client, name=f"StockCat-{sku}")
        res = await client.post(
            f"{BASE}/products",
            json={
                "name": f"Stock item {sku}",
                "sku": sku,
                "branch_id": 1,
                "category_id": cat["id"],
                "unit_price": "10.00",
                "current_stock": stock,
                "reorder_level": "20",
                "unit_of_measure": "pcs",
            },
        )
        assert res.status_code == 201
        return res.json()

    async def test_stock_in_increases_stock(self, test_client: AsyncClient):
        product = await self._setup_product(test_client, "STOCKIN-001", stock="50")
        res = await test_client.post(
            f"{BASE}/stock/in",
            json={
                "product_id": product["id"],
                "branch_id": 1,
                "quantity": "25",
                "reason": "PO received",
            },
        )
        assert res.status_code == 200
        assert Decimal(res.json()["product"]["current_stock"]) == Decimal("75")

    async def test_stock_out_decreases_stock(self, test_client: AsyncClient):
        product = await self._setup_product(test_client, "STOCKOUT-001", stock="80")
        res = await test_client.post(
            f"{BASE}/stock/out",
            json={
                "product_id": product["id"],
                "branch_id": 1,
                "quantity": "30",
                "reason": "Sales",
            },
        )
        assert res.status_code == 200
        assert Decimal(res.json()["product"]["current_stock"]) == Decimal("50")

    async def test_stock_out_insufficient_returns_400(self, test_client: AsyncClient):
        product = await self._setup_product(test_client, "STOCKLOW-001", stock="5")
        res = await test_client.post(
            f"{BASE}/stock/out",
            json={
                "product_id": product["id"],
                "branch_id": 1,
                "quantity": "999",
                "reason": "Impossible request",
            },
        )
        assert res.status_code == 400
        assert "Insufficient stock" in res.json()["detail"]

    async def test_stock_adjust_sets_exact_quantity(self, test_client: AsyncClient):
        product = await self._setup_product(test_client, "STOCKADJ-001", stock="20")
        res = await test_client.post(
            f"{BASE}/stock/adjust",
            json={
                "product_id": product["id"],
                "branch_id": 1,
                "new_quantity": "60",
                "reason": "Physical count",
            },
        )
        assert res.status_code == 200
        assert Decimal(res.json()["product"]["current_stock"]) == Decimal("60")

    async def test_get_movements_for_product(self, test_client: AsyncClient):
        product = await self._setup_product(test_client, "MVMT-001", stock="100")
        # Trigger a stock IN to create a movement
        await test_client.post(
            f"{BASE}/stock/in",
            json={
                "product_id": product["id"],
                "branch_id": 1,
                "quantity": "10",
            },
        )
        res = await test_client.get(f"{BASE}/products/{product['id']}/movements")
        assert res.status_code == 200
        data = res.json()
        assert "movements" in data
        assert len(data["movements"]) >= 1
