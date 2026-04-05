import time
from datetime import datetime, timezone

import orjson
from redis.asyncio import Redis

from app.core.config import get_settings
from app.schemas.collect import BatchCollectRequest, BatchCollectResponse


async def push_batch_to_stream(redis: Redis, batch: BatchCollectRequest) -> BatchCollectResponse:
    settings = get_settings()
    if len(batch.records) > settings.max_batch_size:
        raise ValueError(f'Batch exceeds MAX_BATCH_SIZE={settings.max_batch_size}')

    started = time.perf_counter()

    pipe = redis.pipeline(transaction=False)
    now = datetime.now(timezone.utc).isoformat()

    for rec in batch.records:
        item = {
            b'source': batch.source.encode('utf-8'),
            b'record_id': (rec.record_id or '').encode('utf-8'),
            b'collected_at': (rec.collected_at.isoformat() if rec.collected_at else now).encode('utf-8'),
            b'payload': orjson.dumps(rec.payload),
        }
        pipe.xadd(settings.redis_stream_key, item, maxlen=1_000_000, approximate=True)

    await pipe.execute()

    elapsed_ms = (time.perf_counter() - started) * 1000
    return BatchCollectResponse(
        accepted=len(batch.records),
        source=batch.source,
        stream_key=settings.redis_stream_key,
        processing_ms=round(elapsed_ms, 2),
    )
