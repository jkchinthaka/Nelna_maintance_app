"""Unit tests for app.services.inventory.

Uses an in-memory SQLite database (via aiosqlite) so no real PostgreSQL is
needed.  The fixtures are defined in tests/conftest.py.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
import pytest_asyncio
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inventory import Product, ProductCategory, StockMovementType
from app.schemas.inventory import (
    ProductCategoryCreate,
    ProductCreate,
    StockAdjustRequest,
    StockInRequest,
    StockOutRequest,
)
from app.services import inventory as svc
from tests.conftest import make_admin_user, make_branch_user

pytestmark = pytest.mark.asyncio


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

async def _seed_category(session: AsyncSession) -> ProductCategory:
    cat = ProductCategory(name="Test Category", description="unit-test cat", is_active=True)
    session.add(cat)
    await session.commit()
    await session.refresh(cat)
    return cat


async def _seed_product(session: AsyncSession, category_id: int, **overrides) -> Product:
    defaults = dict(
        name="Test Widget",
        sku="TST-001",
        branch_id=1,
        category_id=category_id,
        unit_price=Decimal("10.00"),
        current_stock=Decimal("50.00"),
        reorder_level=Decimal("10.00"),
        unit_of_measure="pcs",
        is_active=True,
    )
    defaults.update(overrides)
    product = Product(**defaults)
    session.add(product)
    await session.commit()
    await session.refresh(product)
    return product


# ===========================================================================
# CATEGORY tests
# ===========================================================================

class TestCategory:
    async def test_create_category_success(self, db_session: AsyncSession):
        data = ProductCategoryCreate(name="Widgets", description="All widgets")
        cat = await svc.create_category(data, db_session)
        assert cat.id is not None
        assert cat.name == "Widgets"

    async def test_create_category_duplicate_name_raises_409(self, db_session: AsyncSession):
        data = ProductCategoryCreate(name="DupCat")
        await svc.create_category(data, db_session)
        with pytest.raises(HTTPException) as exc_info:
            await svc.create_category(data, db_session)
        assert exc_info.value.status_code == 409

    async def test_get_all_categories_returns_active_only(self, db_session: AsyncSession):
        inactive = ProductCategory(name="Inactive Cat", is_active=False)
        active = ProductCategory(name="Active Cat", is_active=True)
        db_session.add_all([inactive, active])
        await db_session.commit()

        cats = await svc.get_all_categories(db_session)
        names = [c.name for c in cats]
        assert "Active Cat" in names
        assert "Inactive Cat" not in names


# ===========================================================================
# PRODUCT tests
# ===========================================================================

class TestProduct:
    async def test_create_product_success(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        admin = make_admin_user()
        data = ProductCreate(
            name="New Item",
            sku="NI-001",
            branch_id=1,
            category_id=cat.id,
            unit_price=Decimal("5.00"),
            current_stock=Decimal("100"),
            reorder_level=Decimal("20"),
            unit_of_measure="kg",
        )
        product = await svc.create_product(data, admin, db_session)
        assert product.id is not None
        assert product.sku == "NI-001"

    async def test_create_product_duplicate_sku_raises_409(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        admin = make_admin_user()
        data = ProductCreate(
            name="Dup Item",
            sku="DUP-001",
            branch_id=1,
            category_id=cat.id,
            unit_price=Decimal("1.00"),
            current_stock=Decimal("10"),
            reorder_level=Decimal("5"),
            unit_of_measure="pcs",
        )
        await svc.create_product(data, admin, db_session)
        with pytest.raises(HTTPException) as exc_info:
            await svc.create_product(data, admin, db_session)
        assert exc_info.value.status_code == 409

    async def test_get_product_by_id_not_found_raises_404(self, db_session: AsyncSession):
        with pytest.raises(HTTPException) as exc_info:
            await svc.get_product_by_id(99999, db_session)
        assert exc_info.value.status_code == 404

    async def test_delete_product_soft_deletes(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        admin = make_admin_user()
        p = await _seed_product(db_session, cat.id, sku="DEL-001")
        await svc.delete_product(p.id, db_session)
        # After soft delete, get_product_by_id should raise 404
        with pytest.raises(HTTPException) as exc_info:
            await svc.get_product_by_id(p.id, db_session)
        assert exc_info.value.status_code == 404

    async def test_branch_user_sees_only_own_branch(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        # Products in different branches
        p1 = await _seed_product(db_session, cat.id, sku="BR1-001", branch_id=10, name="Branch 10 item")
        p2 = await _seed_product(db_session, cat.id, sku="BR2-001", branch_id=20, name="Branch 20 item")

        branch_user = make_branch_user(branch_id=10)
        result = await svc.get_all_products({}, branch_user, db_session)
        skus = [p.sku for p in result["products"]]
        assert "BR1-001" in skus
        assert "BR2-001" not in skus


# ===========================================================================
# STOCK MOVEMENT tests
# ===========================================================================

class TestStockMovements:
    async def test_stock_in_increases_stock(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        product = await _seed_product(db_session, cat.id, sku="SIN-001", current_stock=Decimal("50"))
        admin = make_admin_user()

        data = StockInRequest(
            product_id=product.id,
            branch_id=1,
            quantity=Decimal("20"),
            reason="Purchase order",
        )
        updated_product, movement = await svc.stock_in(data, admin, db_session)

        assert updated_product.current_stock == Decimal("70")
        assert movement.type == StockMovementType.IN
        assert movement.previous_stock == Decimal("50")
        assert movement.new_stock == Decimal("70")
        assert movement.performed_by == admin.email

    async def test_stock_out_decreases_stock(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        product = await _seed_product(db_session, cat.id, sku="SOUT-001", current_stock=Decimal("50"))
        admin = make_admin_user()

        data = StockOutRequest(
            product_id=product.id,
            branch_id=1,
            quantity=Decimal("15"),
            reason="Sales order",
        )
        updated_product, movement = await svc.stock_out(data, admin, db_session)

        assert updated_product.current_stock == Decimal("35")
        assert movement.type == StockMovementType.OUT
        assert movement.previous_stock == Decimal("50")
        assert movement.new_stock == Decimal("35")

    async def test_stock_out_insufficient_raises_400(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        product = await _seed_product(db_session, cat.id, sku="SLOW-001", current_stock=Decimal("5"))
        admin = make_admin_user()

        data = StockOutRequest(
            product_id=product.id,
            branch_id=1,
            quantity=Decimal("100"),  # more than available
            reason="Return",
        )
        with pytest.raises(HTTPException) as exc_info:
            await svc.stock_out(data, admin, db_session)
        assert exc_info.value.status_code == 400
        assert "Insufficient stock" in exc_info.value.detail

    async def test_adjust_stock_sets_exact_quantity(self, db_session: AsyncSession):
        cat = await _seed_category(db_session)
        product = await _seed_product(db_session, cat.id, sku="ADJ-001", current_stock=Decimal("30"))
        admin = make_admin_user()

        data = StockAdjustRequest(
            product_id=product.id,
            branch_id=1,
            new_quantity=Decimal("45"),
            reason="Physical count",
        )
        updated_product, movement = await svc.adjust_stock(data, admin, db_session)

        assert updated_product.current_stock == Decimal("45")
        assert movement.type == StockMovementType.ADJUSTMENT
        assert movement.previous_stock == Decimal("30")
        assert movement.new_stock == Decimal("45")
        # Delta = |45 - 30| = 15
        assert movement.quantity == Decimal("15")

    async def test_stock_movement_on_nonexistent_product_raises_404(self, db_session: AsyncSession):
        admin = make_admin_user()
        data = StockInRequest(
            product_id=99999,
            branch_id=1,
            quantity=Decimal("10"),
        )
        with pytest.raises(HTTPException) as exc_info:
            await svc.stock_in(data, admin, db_session)
        assert exc_info.value.status_code == 404
