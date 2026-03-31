"""
Prometheus metrics: request counters, latency histograms (p95/p99),
Redis stream lag gauge.  Mount /metrics for scraping.
"""
import time
from collections.abc import Awaitable, Callable

from fastapi import Request, Response
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)


# ---------------------------------------------------------------------------
# Metric definitions
# ---------------------------------------------------------------------------

REQUEST_COUNT = Counter(
    'nelna_http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status'],
)

REQUEST_LATENCY = Histogram(
    'nelna_http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
)

REDIS_STREAM_LAG = Gauge(
    'nelna_redis_stream_lag_messages',
    'Unacknowledged messages in the collection stream',
    ['stream_key'],
)

ACTIVE_REQUESTS = Gauge(
    'nelna_http_active_requests',
    'Number of requests currently being processed',
)

# ── AI / ML metrics ──────────────────────────────────────────────────────────

AI_PREDICTION_TOTAL = Counter(
    'nelna_ai_predictions_total',
    'Total AI/ML prediction requests',
    ['feature', 'outcome'],  # feature: maintenance|inventory|anomaly|assistant|image
)                            # outcome: success|error|insufficient_data

AI_PREDICTION_LATENCY = Histogram(
    'nelna_ai_prediction_duration_seconds',
    'AI/ML prediction request duration in seconds',
    ['feature'],
    buckets=(0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0),
)

ANOMALY_ALERTS_TOTAL = Counter(
    'nelna_anomaly_alerts_total',
    'Total anomalies detected by IsolationForest',
    ['stream_key'],
)


# ---------------------------------------------------------------------------
# ASGI middleware
# ---------------------------------------------------------------------------

class PrometheusMiddleware:
    """Starlette / FastAPI compatible timing middleware."""

    def __init__(self, app):
        self.app = app

    async def __call__(
        self,
        scope,
        receive,
        send: Callable[..., Awaitable[None]],
    ) -> None:
        if scope['type'] != 'http':
            await self.app(scope, receive, send)
            return

        request = Request(scope, receive)
        method = request.method
        # Normalise path: strip query params and collapse numeric IDs
        path = request.url.path
        endpoint = _normalise_path(path)

        ACTIVE_REQUESTS.inc()
        start = time.perf_counter()
        status_code = 500

        async def send_wrapper(message):
            nonlocal status_code
            if message['type'] == 'http.response.start':
                status_code = message['status']
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            duration = time.perf_counter() - start
            ACTIVE_REQUESTS.dec()
            REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=str(status_code)).inc()
            REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(duration)


def _normalise_path(path: str) -> str:
    """Replace numeric path segments with {id} to limit cardinality."""
    parts = path.split('/')
    normalised = [
        '{id}' if part.isdigit() else part
        for part in parts
    ]
    return '/'.join(normalised)


# ---------------------------------------------------------------------------
# /metrics endpoint
# ---------------------------------------------------------------------------

async def metrics_endpoint(_request: Request) -> Response:
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST,
    )


# ---------------------------------------------------------------------------
# Helper: update stream lag (call from worker or background task)
# ---------------------------------------------------------------------------

async def update_stream_lag(redis, stream_key: str, consumer_group: str) -> None:
    """Read XINFO GROUPS and update the lag gauge."""
    try:
        groups = await redis.xinfo_groups(stream_key)
        for group in groups:
            name = group.get('name', b'')
            if isinstance(name, bytes):
                name = name.decode()
            if name == consumer_group:
                lag = group.get('lag') or group.get('pending', 0)
                REDIS_STREAM_LAG.labels(stream_key=stream_key).set(lag)
                break
    except Exception:  # noqa: BLE001
        pass
