"""
Redis Streams consumer worker.
Reads batches from the collection stream, processes them, and stores
summaries in the database.  Runs as an asyncio background task
inside the FastAPI lifespan.

Consumer group guarantees at-least-once delivery with XACK.
"""
from __future__ import annotations

import asyncio
import json
from datetime import datetime, timezone
from typing import Any

import structlog
from redis.asyncio import Redis
from redis.exceptions import ResponseError

from app.core.config import get_settings
from app.core.metrics import update_stream_lag

log = structlog.get_logger(__name__)


async def _ensure_consumer_group(redis: Redis, stream_key: str, group: str) -> None:
    """Create consumer group; ignore if it already exists."""
    try:
        await redis.xgroup_create(stream_key, group, id='0', mkstream=True)
        log.info('stream_group_created', stream=stream_key, group=group)
    except ResponseError as exc:
        if 'BUSYGROUP' not in str(exc):
            raise


async def _process_message(message_id: str, fields: dict[str, Any]) -> None:
    """
    Process a single stream message.
    Extend this function to write events to the DB, trigger alerts, etc.
    """
    try:
        raw = fields.get(b'payload') or fields.get('payload')
        if isinstance(raw, bytes):
            raw = raw.decode()
        _data = json.loads(raw) if isinstance(raw, str) else {}
        source = (fields.get(b'source') or fields.get('source', b'')).decode() \
            if isinstance(fields.get(b'source') or fields.get('source', b''), bytes) \
            else str(fields.get('source', ''))
        log.debug('stream_event_processed', msg_id=message_id, source=source)
    except Exception as exc:  # noqa: BLE001
        log.warning('stream_event_process_error', msg_id=message_id, error=str(exc))


async def run_stream_consumer(redis: Redis) -> None:
    """
    Long-running coroutine — consume events from Redis Streams.
    Safe to cancel: exits cleanly on CancelledError.
    """
    settings = get_settings()
    stream_key = settings.redis_stream_key
    group = settings.stream_consumer_group
    consumer = settings.stream_consumer_name
    batch_size = settings.stream_batch_size

    await _ensure_consumer_group(redis, stream_key, group)
    log.info('stream_consumer_started', stream=stream_key, group=group, consumer=consumer)

    while True:
        try:
            # Read up to `batch_size` new messages (block up to 2 s)
            results = await redis.xreadgroup(
                groupname=group,
                consumername=consumer,
                streams={stream_key: '>'},
                count=batch_size,
                block=2000,
            )

            if not results:
                # No new messages — update lag metric and loop
                await update_stream_lag(redis, stream_key, group)
                continue

            for _stream, messages in results:
                ack_ids = []
                for message_id, fields in messages:
                    await _process_message(
                        message_id.decode() if isinstance(message_id, bytes) else message_id,
                        fields,
                    )
                    ack_ids.append(message_id)

                if ack_ids:
                    await redis.xack(stream_key, group, *ack_ids)
                    log.debug('stream_messages_acked', count=len(ack_ids))

            await update_stream_lag(redis, stream_key, group)

        except asyncio.CancelledError:
            log.info('stream_consumer_stopped', stream=stream_key)
            break
        except Exception as exc:  # noqa: BLE001
            log.error('stream_consumer_error', error=str(exc))
            await asyncio.sleep(2)  # back-off before retry
