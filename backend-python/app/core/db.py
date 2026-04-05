from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import get_settings


settings = get_settings()

engine: AsyncEngine | None = None
AsyncSessionLocal: async_sessionmaker[AsyncSession] | None = None

if settings.database_url:
    engine = create_async_engine(
        settings.database_url,
        pool_size=30,
        max_overflow=60,
        pool_pre_ping=True,
        pool_recycle=1800,
        echo=False,
    )
    AsyncSessionLocal = async_sessionmaker(
        engine,
        expire_on_commit=False,
        class_=AsyncSession,
    )


async def get_db() -> AsyncSession:
    """FastAPI dependency — yields a scoped AsyncSession."""
    if AsyncSessionLocal is None:
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail='Database not configured')
    async with AsyncSessionLocal() as session:
        yield session
