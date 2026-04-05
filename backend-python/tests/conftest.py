"""Shared pytest fixtures for unit and integration tests."""
from __future__ import annotations

import asyncio
from decimal import Decimal
from typing import AsyncGenerator
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.security import UserContext


# ---------------------------------------------------------------------------
# Event-loop policy (pytest-asyncio ≥ 0.21 requires explicit mode)
# ---------------------------------------------------------------------------
pytest_plugins = ("pytest_asyncio",)


# ---------------------------------------------------------------------------
# In-memory SQLite engine (mirrors Postgres schema closely enough for unit tests)
# ---------------------------------------------------------------------------
@pytest_asyncio.fixture(scope="session")
async def db_engine():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    from app.models import Base  # noqa: PLC0415
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def db_session(db_engine) -> AsyncGenerator[AsyncSession, None]:
    Session = async_sessionmaker(db_engine, expire_on_commit=False)
    async with Session() as session:
        yield session
        await session.rollback()


# ---------------------------------------------------------------------------
# Stub UserContext helpers
# ---------------------------------------------------------------------------
def make_admin_user(**overrides) -> UserContext:
    defaults = dict(
        id=1,
        company_id=1,
        branch_id=1,
        role_id=1,
        role_name="company_admin",
        email="admin@nelna.local",
        permissions=[],
    )
    defaults.update(overrides)
    return UserContext(**defaults)


def make_branch_user(**overrides) -> UserContext:
    defaults = dict(
        id=2,
        company_id=1,
        branch_id=2,
        role_id=5,
        role_name="branch_manager",
        email="branch@nelna.local",
        permissions=[
            {"module": "inventory", "action": "read", "resource": "*"},
            {"module": "inventory", "action": "create", "resource": "*"},
            {"module": "inventory", "action": "update", "resource": "*"},
        ],
    )
    defaults.update(overrides)
    return UserContext(**defaults)


# ---------------------------------------------------------------------------
# FastAPI TestClient with mocked DB + auth
# ---------------------------------------------------------------------------
@pytest_asyncio.fixture
async def test_client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    from app.main import app  # noqa: PLC0415
    from app.core import db as db_module  # noqa: PLC0415
    from app.core.security import get_current_user  # noqa: PLC0415

    admin = make_admin_user()

    # Patch DB session so routes use the test SQLite session
    async def override_get_db():
        yield db_session

    async def override_get_current_user(*_args, **_kwargs):
        return admin

    app.dependency_overrides[db_module.get_db] = override_get_db
    app.dependency_overrides[get_current_user] = override_get_current_user

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        yield client

    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Mock Redis
# ---------------------------------------------------------------------------
@pytest.fixture
def mock_redis() -> MagicMock:
    r = MagicMock()
    r.xadd = AsyncMock(return_value="1234567890-0")
    r.xreadgroup = AsyncMock(return_value=[])
    r.xack = AsyncMock(return_value=1)
    r.xgroup_create = AsyncMock(return_value=True)
    r.xinfo_groups = AsyncMock(return_value=[{"name": "nelna-python-workers", "pending": 0}])
    return r
