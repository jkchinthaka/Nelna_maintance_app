from fastapi import APIRouter
from sqlalchemy import text

from app.core.db import engine


router = APIRouter(tags=['health'])


@router.get('/health')
async def health() -> dict[str, str]:
    if engine is not None:
        async with engine.connect() as conn:
            await conn.execute(text('SELECT 1'))
        return {'status': 'ok', 'service': 'nelna-python-api', 'database': 'up'}

    return {'status': 'ok', 'service': 'nelna-python-api', 'database': 'not-configured'}
