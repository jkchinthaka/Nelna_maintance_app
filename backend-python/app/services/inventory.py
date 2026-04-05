"""
Async inventory business logic.
Mirrors backend/src/services/inventory.service.js behaviour.
All DB operations use SQLAlchemy asyncio ORM + raw SQL where needed.
"""
from __future__ import annotations

import math
from decimal import Decimal

import structlog
from fastapi import HTTPException
from sqlalchemy import func, select, text, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import UserContext
from app.models.inventory import (
    Product,
    ProductCategory,
    StockMovement,
    StockMovementType,
    Supplier,
)
from app.schemas.inventory import (
    ProductCategoryCreate,
    ProductCategoryUpdate,
    ProductCreate,
    ProductUpdate,
    StockAdjustRequest,
    StockInRequest,
    StockOutRequest,
    SupplierCreate,
    SupplierUpdate,
)

log = structlog.get_logger(__name__)

_ALLOWED_PRODUCT_SORT = {'created_at', 'name', 'sku', 'current_stock', 'unit_price'}


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _paginate(page: int, limit: int) -> tuple[int, int, int]:
    page = max(1, page)
    limit = max(1, min(limit, 100))
    skip = (page - 1) * limit
    return page, limit, skip


# ===========================================================================
# CATEGORIES
# ===========================================================================

async def get_all_categories(session: AsyncSession) -> list[ProductCategory]:
    result = await session.execute(
        select(ProductCategory).where(ProductCategory.is_active.is_(True)).order_by(ProductCategory.name)
    )
    return list(result.scalars().all())


async def create_category(data: ProductCategoryCreate, session: AsyncSession) -> ProductCategory:
    existing = await session.execute(
        select(ProductCategory).where(ProductCategory.name == data.name)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail='Category with this name already exists')

    cat = ProductCategory(**data.model_dump())
    session.add(cat)
    await session.commit()
    await session.refresh(cat)
    return cat


async def update_category(
    category_id: int,
    data: ProductCategoryUpdate,
    session: AsyncSession,
) -> ProductCategory:
    cat = await session.get(ProductCategory, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail='Category not found')

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(cat, field, value)

    await session.commit()
    await session.refresh(cat)
    return cat


# ===========================================================================
# PRODUCTS
# ===========================================================================

async def get_all_products(
    query: dict,
    user: UserContext,
    session: AsyncSession,
) -> dict:
    page, limit, skip = _paginate(int(query.get('page', 1)), int(query.get('limit', 20)))

    # Base filters
    filters = [Product.deleted_at.is_(None)]

    if query.get('categoryId'):
        filters.append(Product.category_id == int(query['categoryId']))

    if query.get('branchId'):
        filters.append(Product.branch_id == int(query['branchId']))
    elif user.role_name not in ('super_admin', 'company_admin') and user.branch_id:
        filters.append(Product.branch_id == user.branch_id)

    if query.get('isActive') is not None:
        filters.append(Product.is_active == (query['isActive'] == 'true'))

    search = query.get('search', '').strip()
    if search:
        like = f'%{search}%'
        from sqlalchemy import or_
        filters.append(
            or_(
                Product.name.ilike(like),
                Product.sku.ilike(like),
                Product.barcode.ilike(like),
            )
        )

    if query.get('lowStock') == 'true':
        filters.append(Product.current_stock <= Product.reorder_level)

    # Sort
    sort_field = query.get('sortBy', 'created_at')
    if sort_field not in _ALLOWED_PRODUCT_SORT:
        sort_field = 'created_at'
    sort_attr = getattr(Product, sort_field)
    order_expr = sort_attr.desc() if query.get('order', 'desc') == 'desc' else sort_attr.asc()

    stmt = (
        select(Product)
        .where(*filters)
        .options(selectinload(Product.category))
        .order_by(order_expr)
        .offset(skip)
        .limit(limit)
    )
    count_stmt = select(func.count()).select_from(Product).where(*filters)

    products_result = await session.execute(stmt)
    count_result = await session.execute(count_stmt)

    products = list(products_result.scalars().all())
    total = count_result.scalar_one()

    return {
        'products': products,
        'pagination': {
            'page': page,
            'limit': limit,
            'total': total,
            'total_pages': math.ceil(total / limit) if total else 0,
        },
    }


async def get_product_by_id(product_id: int, session: AsyncSession) -> Product:
    result = await session.execute(
        select(Product)
        .where(Product.id == product_id, Product.deleted_at.is_(None))
        .options(
            selectinload(Product.category),
            selectinload(Product.stock_movements),
        )
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail='Product not found')
    return product


async def create_product(data: ProductCreate, user: UserContext, session: AsyncSession) -> Product:
    # Duplicate SKU check within branch
    existing = await session.execute(
        select(Product).where(
            Product.sku == data.sku,
            Product.branch_id == data.branch_id,
            Product.deleted_at.is_(None),
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail='A product with this SKU already exists in this branch')

    if data.category_id:
        cat = await session.get(ProductCategory, data.category_id)
        if not cat:
            raise HTTPException(status_code=404, detail='Product category not found')

    product = Product(**data.model_dump())
    session.add(product)
    await session.commit()
    await session.refresh(product, ['category'])
    log.info('product_created', product_id=product.id, sku=product.sku, user_id=user.id)
    return product


async def update_product(
    product_id: int,
    data: ProductUpdate,
    session: AsyncSession,
) -> Product:
    product = await session.get(Product, product_id)
    if not product or product.deleted_at:
        raise HTTPException(status_code=404, detail='Product not found')

    updates = data.model_dump(exclude_none=True)

    if 'sku' in updates and updates['sku'] != product.sku:
        conflict = await session.execute(
            select(Product).where(
                Product.sku == updates['sku'],
                Product.branch_id == product.branch_id,
                Product.deleted_at.is_(None),
                Product.id != product_id,
            )
        )
        if conflict.scalar_one_or_none():
            raise HTTPException(status_code=409, detail='A product with this SKU already exists in this branch')

    if 'category_id' in updates and updates['category_id']:
        cat = await session.get(ProductCategory, updates['category_id'])
        if not cat:
            raise HTTPException(status_code=404, detail='Product category not found')

    for field, value in updates.items():
        setattr(product, field, value)

    await session.commit()
    await session.refresh(product, ['category'])
    return product


async def delete_product(product_id: int, session: AsyncSession) -> None:
    product = await session.get(Product, product_id)
    if not product or product.deleted_at:
        raise HTTPException(status_code=404, detail='Product not found')

    from datetime import datetime, timezone
    product.deleted_at = datetime.now(timezone.utc)
    product.is_active = False
    await session.commit()


# ===========================================================================
# STOCK MOVEMENTS
# ===========================================================================

async def stock_in(
    data: StockInRequest,
    user: UserContext,
    session: AsyncSession,
) -> tuple[Product, StockMovement]:
    async with session.begin():
        product = await session.get(Product, data.product_id)
        if not product or product.deleted_at:
            raise HTTPException(status_code=404, detail='Product not found')

        previous = product.current_stock
        product.current_stock = previous + data.quantity

        movement = StockMovement(
            branch_id=data.branch_id,
            product_id=data.product_id,
            type=StockMovementType.IN,
            quantity=data.quantity,
            unit_cost=data.unit_cost,
            reference_type=data.reference_type,
            reference_id=data.reference_id,
            reason=data.reason,
            previous_stock=previous,
            new_stock=product.current_stock,
            performed_by=user.email,
        )
        session.add(movement)

    await session.refresh(product)
    await session.refresh(movement)
    log.info('stock_in', product_id=product.id, qty=str(data.quantity), user=user.email)
    return product, movement


async def stock_out(
    data: StockOutRequest,
    user: UserContext,
    session: AsyncSession,
) -> tuple[Product, StockMovement]:
    async with session.begin():
        product = await session.get(Product, data.product_id)
        if not product or product.deleted_at:
            raise HTTPException(status_code=404, detail='Product not found')

        if product.current_stock < data.quantity:
            raise HTTPException(
                status_code=400,
                detail=f'Insufficient stock. Available: {product.current_stock}, Requested: {data.quantity}',
            )

        previous = product.current_stock
        product.current_stock = previous - data.quantity

        movement = StockMovement(
            branch_id=data.branch_id,
            product_id=data.product_id,
            type=StockMovementType.OUT,
            quantity=data.quantity,
            unit_cost=data.unit_cost,
            reference_type=data.reference_type,
            reference_id=data.reference_id,
            reason=data.reason,
            previous_stock=previous,
            new_stock=product.current_stock,
            performed_by=user.email,
        )
        session.add(movement)

    await session.refresh(product)
    await session.refresh(movement)
    log.info('stock_out', product_id=product.id, qty=str(data.quantity), user=user.email)
    return product, movement


async def adjust_stock(
    data: StockAdjustRequest,
    user: UserContext,
    session: AsyncSession,
) -> tuple[Product, StockMovement]:
    async with session.begin():
        product = await session.get(Product, data.product_id)
        if not product or product.deleted_at:
            raise HTTPException(status_code=404, detail='Product not found')

        previous = product.current_stock
        delta = data.new_quantity - previous
        product.current_stock = data.new_quantity

        movement = StockMovement(
            branch_id=data.branch_id,
            product_id=data.product_id,
            type=StockMovementType.ADJUSTMENT,
            quantity=abs(delta),
            reason=data.reason,
            previous_stock=previous,
            new_stock=data.new_quantity,
            performed_by=user.email,
        )
        session.add(movement)

    await session.refresh(product)
    await session.refresh(movement)
    log.info('stock_adjust', product_id=product.id, delta=str(delta), user=user.email)
    return product, movement


async def get_stock_movements(
    product_id: int,
    query: dict,
    session: AsyncSession,
) -> dict:
    page, limit, skip = _paginate(int(query.get('page', 1)), int(query.get('limit', 20)))

    filters = [StockMovement.product_id == product_id]
    if query.get('type'):
        filters.append(StockMovement.type == StockMovementType(query['type']))

    stmt = (
        select(StockMovement)
        .where(*filters)
        .order_by(StockMovement.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    count_stmt = select(func.count()).select_from(StockMovement).where(*filters)

    movements = list((await session.execute(stmt)).scalars().all())
    total = (await session.execute(count_stmt)).scalar_one()

    return {
        'movements': movements,
        'pagination': {
            'page': page,
            'limit': limit,
            'total': total,
            'total_pages': math.ceil(total / limit) if total else 0,
        },
    }


async def get_low_stock_alerts(query: dict, user: UserContext, session: AsyncSession) -> dict:
    return await get_all_products({**query, 'lowStock': 'true'}, user, session)


# ===========================================================================
# SUPPLIERS
# ===========================================================================

async def get_all_suppliers(query: dict, session: AsyncSession) -> dict:
    page, limit, skip = _paginate(int(query.get('page', 1)), int(query.get('limit', 20)))

    filters = [Supplier.deleted_at.is_(None)]
    search = query.get('search', '').strip()
    if search:
        like = f'%{search}%'
        from sqlalchemy import or_
        filters.append(or_(Supplier.name.ilike(like), Supplier.code.ilike(like)))

    stmt = (
        select(Supplier)
        .where(*filters)
        .order_by(Supplier.name)
        .offset(skip)
        .limit(limit)
    )
    count_stmt = select(func.count()).select_from(Supplier).where(*filters)

    suppliers = list((await session.execute(stmt)).scalars().all())
    total = (await session.execute(count_stmt)).scalar_one()

    return {
        'suppliers': suppliers,
        'pagination': {
            'page': page,
            'limit': limit,
            'total': total,
            'total_pages': math.ceil(total / limit) if total else 0,
        },
    }


async def get_supplier_by_id(supplier_id: int, session: AsyncSession) -> Supplier:
    supplier = await session.get(Supplier, supplier_id)
    if not supplier or supplier.deleted_at:
        raise HTTPException(status_code=404, detail='Supplier not found')
    return supplier


async def create_supplier(data: SupplierCreate, session: AsyncSession) -> Supplier:
    existing = await session.execute(
        select(Supplier).where(Supplier.code == data.code, Supplier.deleted_at.is_(None))
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail='Supplier with this code already exists')

    supplier = Supplier(**data.model_dump())
    session.add(supplier)
    await session.commit()
    await session.refresh(supplier)
    return supplier


async def update_supplier(
    supplier_id: int,
    data: SupplierUpdate,
    session: AsyncSession,
) -> Supplier:
    supplier = await session.get(Supplier, supplier_id)
    if not supplier or supplier.deleted_at:
        raise HTTPException(status_code=404, detail='Supplier not found')

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(supplier, field, value)

    await session.commit()
    await session.refresh(supplier)
    return supplier
