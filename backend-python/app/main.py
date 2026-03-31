import asyncio
from contextlib import asynccontextmanager

import httpx
import structlog.contextvars as _cv
from fastapi import FastAPI, Request
from fastapi.responses import ORJSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.api.router import api_router
from app.core.cache import create_redis_client
from app.core.config import get_settings
from app.core.logging import new_correlation_id, setup_logging
from app.core.metrics import PrometheusMiddleware, metrics_endpoint
from app.workers.stream_consumer import run_stream_consumer


settings = get_settings()
setup_logging(settings.log_level)

# ── Sentry initialisation (must happen before app creation) ─────────────────
if settings.sentry_dsn:
    import sentry_sdk
    from sentry_sdk.integrations.fastapi import FastApiIntegration
    from sentry_sdk.integrations.httpx import HttpxIntegration
    from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.app_env,
        traces_sample_rate=settings.sentry_traces_sample_rate,
        profiles_sample_rate=settings.sentry_profiles_sample_rate,
        integrations=[
            FastApiIntegration(transaction_style='endpoint'),
            SqlalchemyIntegration(),
            HttpxIntegration(),
        ],
        # Never send raw JWT or API keys to Sentry
        send_default_pii=False,
    )

log = __import__('structlog').get_logger(__name__)

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

# ── Correlation-ID middleware (outermost — runs before everything else) ──────
@app.middleware('http')
async def correlation_id_middleware(request: Request, call_next):
    """
    Reads X-Request-ID / X-Correlation-ID from the incoming request (set by
    Nginx or the Flutter client) or generates a new one.  Injects it into the
    structlog context so every log line emitted during the request carries it.
    Also sets the Sentry transaction tag when Sentry is active.
    """
    cid = (
        request.headers.get('x-request-id')
        or request.headers.get('x-correlation-id')
        or new_correlation_id()
    )
    _cv.bind_contextvars(correlation_id=cid)

    if settings.sentry_dsn:
        import sentry_sdk
        sentry_sdk.set_tag('correlation_id', cid)

    response = await call_next(request)

    response.headers['X-Correlation-ID'] = cid
    _cv.clear_contextvars()
    return response


# ── Global unhandled-exception handler ──────────────────────────────────────
@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    log.error(
        'Unhandled exception',
        exc_info=exc,
        path=request.url.path,
        method=request.method,
    )
    if settings.sentry_dsn:
        import sentry_sdk
        sentry_sdk.capture_exception(exc)
    return ORJSONResponse(
        status_code=500,
        content={'detail': 'Internal server error'},
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
