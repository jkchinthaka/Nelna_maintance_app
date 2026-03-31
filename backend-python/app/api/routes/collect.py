from fastapi import APIRouter, Depends, HTTPException, Request
from redis.asyncio import Redis
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import get_settings
from app.schemas.collect import BatchCollectRequest, BatchCollectResponse
from app.services.collector import push_batch_to_stream


router = APIRouter(prefix='/collect', tags=['collect'])
limiter = Limiter(key_func=get_remote_address)


def get_redis(request: Request) -> Redis:
    return request.app.state.redis


@router.post('/batch', response_model=BatchCollectResponse)
@limiter.limit(get_settings().rate_limit_collect)
async def collect_batch(
    request: Request,
    payload: BatchCollectRequest,
    redis: Redis = Depends(get_redis),
) -> BatchCollectResponse:
    try:
        return await push_batch_to_stream(redis, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
