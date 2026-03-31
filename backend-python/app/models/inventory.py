"""
SQLAlchemy async ORM models for the Inventory module.
Column names mirror the Prisma schema exactly (snake_case DB columns).
"""
from __future__ import annotations

import enum
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models import Base


class StockMovementType(str, enum.Enum):
    IN = 'IN'
    OUT = 'OUT'
    ADJUSTMENT = 'ADJUSTMENT'
    TRANSFER = 'TRANSFER'
    RETURN = 'RETURN'
    WASTE = 'WASTE'


class ProductCategory(Base):
    __tablename__ = 'product_categories'

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    parent_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey('product_categories.id', ondelete='NO ACTION'), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    products: Mapped[list[Product]] = relationship('Product', back_populates='category', lazy='select')
    parent: Mapped[ProductCategory | None] = relationship(
        'ProductCategory', remote_side='ProductCategory.id', lazy='select'
    )


class Product(Base):
    __tablename__ = 'products'

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    branch_id: Mapped[int] = mapped_column(Integer, ForeignKey('branches.id'), nullable=False)
    category_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey('product_categories.id'), nullable=True
    )
    sku: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    barcode: Mapped[str | None] = mapped_column(String(100), unique=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    unit: Mapped[str] = mapped_column(String(50), nullable=False)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    cost_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    current_stock: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal('0'))
    minimum_stock: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal('0'))
    maximum_stock: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    reorder_level: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal('0'))
    reorder_quantity: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    location: Mapped[str | None] = mapped_column(String(255))
    image_url: Mapped[str | None] = mapped_column(String(500))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    category: Mapped[ProductCategory | None] = relationship(
        'ProductCategory', back_populates='products', lazy='select'
    )
    stock_movements: Mapped[list[StockMovement]] = relationship(
        'StockMovement', back_populates='product', lazy='select'
    )


class StockMovement(Base):
    __tablename__ = 'stock_movements'

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    branch_id: Mapped[int] = mapped_column(Integer, ForeignKey('branches.id'), nullable=False)
    product_id: Mapped[int] = mapped_column(Integer, ForeignKey('products.id'), nullable=False)
    type: Mapped[StockMovementType] = mapped_column(
        Enum(StockMovementType, name='stock_movement_type'), nullable=False
    )
    quantity: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    unit_cost: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    reference_type: Mapped[str | None] = mapped_column(String(100))
    reference_id: Mapped[int | None] = mapped_column(Integer)
    reason: Mapped[str | None] = mapped_column(Text)
    previous_stock: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    new_stock: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    performed_by: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    product: Mapped[Product] = relationship('Product', back_populates='stock_movements', lazy='select')


class Supplier(Base):
    __tablename__ = 'suppliers'

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    contact_person: Mapped[str | None] = mapped_column(String(255))
    email: Mapped[str | None] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(50))
    address: Mapped[str | None] = mapped_column(Text)
    tax_id: Mapped[str | None] = mapped_column(String(100))
    bank_details: Mapped[str | None] = mapped_column(Text)
    payment_terms: Mapped[str | None] = mapped_column(String(255))
    rating: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
