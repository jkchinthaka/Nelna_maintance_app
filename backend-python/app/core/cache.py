from redis.asyncio import Redis

from app.core.config import get_settings


settings = get_settings()


def create_redis_client() -> Redis:
    return Redis.from_url(
        settings.redis_url,
        decode_responses=False,
        max_connections=200,
        socket_timeout=2,
        socket_connect_timeout=2,
        health_check_interval=30,
    )
