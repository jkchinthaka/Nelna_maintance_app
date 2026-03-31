"""
REST API routes for the Inventory module.
These are served natively by Python — no proxy to Node.
Auth is enforced via require_permission.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import UserContext, require_permission
from app.schemas.inventory import (
    PaginatedResponse,
    ProductCategoryCreate,
    ProductCategoryResponse,
    ProductCategoryUpdate,
    ProductCreate,
    ProductResponse,
    ProductUpdate,
    StockAdjustRequest,
    StockInRequest,
    StockMovementResponse,
    StockOutRequest,
    SupplierCreate,
    SupplierResponse,
    SupplierUpdate,
)
from app.services import inventory as svc

router = APIRouter(prefix='/inventory', tags=['inventory'])


# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------

@router.get('/categories', response_model=list[ProductCategoryResponse])
async def list_categories(
    user: UserContext = Depends(require_permission('inventory', 'read')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.get_all_categories(session)


@router.post('/categories', response_model=ProductCategoryResponse, status_code=201)
async def create_category(
    body: ProductCategoryCreate,
    user: UserContext = Depends(require_permission('inventory', 'create')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.create_category(body, session)


@router.put('/categories/{category_id}', response_model=ProductCategoryResponse)
async def update_category(
    category_id: int,
    body: ProductCategoryUpdate,
    user: UserContext = Depends(require_permission('inventory', 'update')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.update_category(category_id, body, session)


# ---------------------------------------------------------------------------
# Products — low-stock alert MUST come before /{product_id} to avoid clash
# ---------------------------------------------------------------------------

@router.get('/products/low-stock', response_model=PaginatedResponse)
async def low_stock_alerts(
    request: Request,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    user: UserContext = Depends(require_permission('inventory', 'read')),
    session: AsyncSession = Depends(get_db),
):
    result = await svc.get_low_stock_alerts(
        {'page': page, 'limit': limit, **dict(request.query_params)},
        user,
        session,
    )
    return {
        'data': [ProductResponse.model_validate(p) for p in result['products']],
        'pagination': result['pagination'],
    }


@router.get('/products', response_model=PaginatedResponse)
async def list_products(
    request: Request,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    user: UserContext = Depends(require_permission('inventory', 'read')),
    session: AsyncSession = Depends(get_db),
):
    result = await svc.get_all_products(
        {'page': page, 'limit': limit, **dict(request.query_params)},
        user,
        session,
    )
    return {
        'data': [ProductResponse.model_validate(p) for p in result['products']],
        'pagination': result['pagination'],
    }


@router.post('/products', response_model=ProductResponse, status_code=201)
async def create_product(
    body: ProductCreate,
    user: UserContext = Depends(require_permission('inventory', 'create')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.create_product(body, user, session)


@router.get('/products/{product_id}', response_model=ProductResponse)
async def get_product(
    product_id: int,
    user: UserContext = Depends(require_permission('inventory', 'read')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.get_product_by_id(product_id, session)


@router.put('/products/{product_id}', response_model=ProductResponse)
async def update_product(
    product_id: int,
    body: ProductUpdate,
    user: UserContext = Depends(require_permission('inventory', 'update')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.update_product(product_id, body, session)


@router.delete('/products/{product_id}', status_code=204)
async def delete_product(
    product_id: int,
    user: UserContext = Depends(require_permission('inventory', 'delete')),
    session: AsyncSession = Depends(get_db),
):
    await svc.delete_product(product_id, session)


@router.get('/products/{product_id}/movements', response_model=PaginatedResponse)
async def get_movements(
    product_id: int,
    request: Request,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    user: UserContext = Depends(require_permission('inventory', 'read')),
    session: AsyncSession = Depends(get_db),
):
    result = await svc.get_stock_movements(
        product_id,
        {'page': page, 'limit': limit, **dict(request.query_params)},
        session,
    )
    return {
        'data': [StockMovementResponse.model_validate(m) for m in result['movements']],
        'pagination': result['pagination'],
    }


# ---------------------------------------------------------------------------
# Stock operations
# ---------------------------------------------------------------------------

@router.post('/stock/in', response_model=StockMovementResponse, status_code=201)
async def stock_in(
    body: StockInRequest,
    user: UserContext = Depends(require_permission('inventory', 'update')),
    session: AsyncSession = Depends(get_db),
):
    _product, movement = await svc.stock_in(body, user, session)
    return movement


@router.post('/stock/out', response_model=StockMovementResponse, status_code=201)
async def stock_out(
    body: StockOutRequest,
    user: UserContext = Depends(require_permission('inventory', 'update')),
    session: AsyncSession = Depends(get_db),
):
    _product, movement = await svc.stock_out(body, user, session)
    return movement


@router.post('/stock/adjust', response_model=StockMovementResponse, status_code=201)
async def adjust_stock(
    body: StockAdjustRequest,
    user: UserContext = Depends(require_permission('inventory', 'update')),
    session: AsyncSession = Depends(get_db),
):
    _product, movement = await svc.adjust_stock(body, user, session)
    return movement


# ---------------------------------------------------------------------------
# Suppliers
# ---------------------------------------------------------------------------

@router.get('/suppliers', response_model=PaginatedResponse)
async def list_suppliers(
    request: Request,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    user: UserContext = Depends(require_permission('inventory', 'read')),
    session: AsyncSession = Depends(get_db),
):
    result = await svc.get_all_suppliers(
        {'page': page, 'limit': limit, **dict(request.query_params)},
        session,
    )
    return {
        'data': [SupplierResponse.model_validate(s) for s in result['suppliers']],
        'pagination': result['pagination'],
    }


@router.get('/suppliers/{supplier_id}', response_model=SupplierResponse)
async def get_supplier(
    supplier_id: int,
    user: UserContext = Depends(require_permission('inventory', 'read')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.get_supplier_by_id(supplier_id, session)


@router.post('/suppliers', response_model=SupplierResponse, status_code=201)
async def create_supplier(
    body: SupplierCreate,
    user: UserContext = Depends(require_permission('inventory', 'create')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.create_supplier(body, session)


@router.put('/suppliers/{supplier_id}', response_model=SupplierResponse)
async def update_supplier(
    supplier_id: int,
    body: SupplierUpdate,
    user: UserContext = Depends(require_permission('inventory', 'update')),
    session: AsyncSession = Depends(get_db),
):
    return await svc.update_supplier(supplier_id, body, session)
