import asyncio
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import ORJSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.api.router import api_router
from app.core.cache import create_redis_client
from app.core.config import get_settings
from app.core.logging import setup_logging
from app.core.metrics import PrometheusMiddleware, metrics_endpoint
from app.workers.stream_consumer import run_stream_consumer


settings = get_settings()
setup_logging(settings.log_level)

# Rate limiter (key = client IP)
limiter = Limiter(key_func=get_remote_address, default_limits=[])


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.redis = create_redis_client()
    app.state.http = httpx.AsyncClient(
        timeout=settings.proxy_timeout_seconds,
        limits=httpx.Limits(max_keepalive_connections=200, max_connections=500),
        http2=True,
    )
    # Start Redis stream consumer as background task
    consumer_task = asyncio.create_task(run_stream_consumer(app.state.redis))

    try:
        yield
    finally:
        # Graceful shutdown
        consumer_task.cancel()
        try:
            await consumer_task
        except asyncio.CancelledError:
            pass
        await app.state.http.aclose()
        await app.state.redis.aclose()


app = FastAPI(
    title=settings.app_name,
    version='2.0.0-python-migration',
    default_response_class=ORJSONResponse,
    lifespan=lifespan,
)

# ---- Middleware (order matters: outermost first) ----
app.add_middleware(PrometheusMiddleware)

# ---- Rate-limit error handler ----
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ---- Prometheus scrape endpoint ----
app.add_route('/metrics', metrics_endpoint, include_in_schema=False)

# ---- API routes ----
app.include_router(api_router)
