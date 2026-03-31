from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Shared SQLAlchemy declarative base for all ORM models."""


# Import all models here so that Base.metadata is fully populated
# before any call to metadata.create_all() (e.g. in tests or migrations).
from app.models.inventory import (  # noqa: E402, F401
    Product,
    ProductCategory,
    StockMovement,
    Supplier,
)
