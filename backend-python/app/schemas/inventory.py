"""Pydantic v2 request/response schemas for the Inventory module."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.inventory import StockMovementType


# ---------------------------------------------------------------------------
# Shared
# ---------------------------------------------------------------------------

class BranchSlim(BaseModel):
    id: int
    name: str
    code: str


class CategorySlim(BaseModel):
    id: int
    name: str


# ---------------------------------------------------------------------------
# ProductCategory
# ---------------------------------------------------------------------------

class ProductCategoryCreate(BaseModel):
    name: str = Field(min_length=2, max_length=255)
    description: str | None = None
    parent_id: int | None = None


class ProductCategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=255)
    description: str | None = None
    parent_id: int | None = None
    is_active: bool | None = None


class ProductCategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str | None
    parent_id: int | None
    is_active: bool
    created_at: datetime


# ---------------------------------------------------------------------------
# Product
# ---------------------------------------------------------------------------

class ProductCreate(BaseModel):
    branch_id: int
    category_id: int | None = None
    sku: str = Field(min_length=1, max_length=100)
    barcode: str | None = Field(default=None, max_length=100)
    name: str = Field(min_length=2, max_length=255)
    description: str | None = None
    unit: str = Field(min_length=1, max_length=50)
    unit_price: Decimal = Field(gt=Decimal('0'))
    cost_price: Decimal | None = None
    current_stock: Decimal = Field(default=Decimal('0'), ge=Decimal('0'))
    minimum_stock: Decimal = Field(default=Decimal('0'), ge=Decimal('0'))
    maximum_stock: Decimal | None = None
    reorder_level: Decimal = Field(default=Decimal('0'), ge=Decimal('0'))
    reorder_quantity: Decimal | None = None
    location: str | None = None

    @field_validator('maximum_stock')
    @classmethod
    def max_gte_min(cls, v: Decimal | None, info: Any) -> Decimal | None:
        if v is not None and 'minimum_stock' in info.data:
            if v < info.data['minimum_stock']:
                raise ValueError('maximum_stock must be >= minimum_stock')
        return v


class ProductUpdate(BaseModel):
    category_id: int | None = None
    sku: str | None = Field(default=None, min_length=1, max_length=100)
    barcode: str | None = None
    name: str | None = Field(default=None, min_length=2, max_length=255)
    description: str | None = None
    unit: str | None = None
    unit_price: Decimal | None = Field(default=None, gt=Decimal('0'))
    cost_price: Decimal | None = None
    minimum_stock: Decimal | None = Field(default=None, ge=Decimal('0'))
    maximum_stock: Decimal | None = None
    reorder_level: Decimal | None = Field(default=None, ge=Decimal('0'))
    reorder_quantity: Decimal | None = None
    location: str | None = None
    is_active: bool | None = None


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    branch_id: int
    category_id: int | None
    sku: str
    barcode: str | None
    name: str
    description: str | None
    unit: str
    unit_price: Decimal
    cost_price: Decimal | None
    current_stock: Decimal
    minimum_stock: Decimal
    maximum_stock: Decimal | None
    reorder_level: Decimal
    reorder_quantity: Decimal | None
    location: str | None
    image_url: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime
    category: CategorySlim | None = None


# ---------------------------------------------------------------------------
# StockMovement
# ---------------------------------------------------------------------------

class StockInRequest(BaseModel):
    product_id: int
    branch_id: int
    quantity: Decimal = Field(gt=Decimal('0'))
    unit_cost: Decimal | None = None
    reference_type: str | None = None
    reference_id: int | None = None
    reason: str | None = None


class StockOutRequest(BaseModel):
    product_id: int
    branch_id: int
    quantity: Decimal = Field(gt=Decimal('0'))
    unit_cost: Decimal | None = None
    reference_type: str | None = None
    reference_id: int | None = None
    reason: str | None = None


class StockAdjustRequest(BaseModel):
    product_id: int
    branch_id: int
    new_quantity: Decimal = Field(ge=Decimal('0'))
    reason: str = Field(min_length=3)


class StockMovementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    branch_id: int
    product_id: int
    type: StockMovementType
    quantity: Decimal
    unit_cost: Decimal | None
    reference_type: str | None
    reference_id: int | None
    reason: str | None
    previous_stock: Decimal
    new_stock: Decimal
    performed_by: str | None
    created_at: datetime


# ---------------------------------------------------------------------------
# Supplier
# ---------------------------------------------------------------------------

class SupplierCreate(BaseModel):
    name: str = Field(min_length=2, max_length=255)
    code: str = Field(min_length=2, max_length=50)
    contact_person: str | None = None
    email: str | None = None
    phone: str | None = None
    address: str | None = None
    tax_id: str | None = None
    bank_details: str | None = None
    payment_terms: str | None = None


class SupplierUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=255)
    contact_person: str | None = None
    email: str | None = None
    phone: str | None = None
    address: str | None = None
    tax_id: str | None = None
    bank_details: str | None = None
    payment_terms: str | None = None
    rating: int | None = Field(default=None, ge=0, le=5)
    is_active: bool | None = None


class SupplierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    code: str
    contact_person: str | None
    email: str | None
    phone: str | None
    address: str | None
    tax_id: str | None
    payment_terms: str | None
    rating: int
    is_active: bool
    created_at: datetime


# ---------------------------------------------------------------------------
# Pagination wrapper
# ---------------------------------------------------------------------------

class Pagination(BaseModel):
    page: int
    limit: int
    total: int
    total_pages: int


class PaginatedResponse(BaseModel):
    data: list[Any]
    pagination: Pagination
