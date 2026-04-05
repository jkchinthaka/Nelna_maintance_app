"""
Logging — Nelna Python Backend
================================
• structlog with JSON output (ISO timestamps, log level, caller location)
• Sentry SDK integration — auto-captures ERROR+ logs and unhandled exceptions
• Correlation ID injected from X-Request-ID / X-Correlation-ID headers
  (populated by SentryRequestIdMiddleware in main.py)
"""
from __future__ import annotations

import logging
import sys
import uuid

import structlog


def setup_logging(level: str = 'INFO') -> None:
    log_level = getattr(logging, level.upper(), logging.INFO)

    # Root stdlib logging — structlog will forward its output here
    logging.basicConfig(
        stream=sys.stdout,
        format='%(message)s',
        level=log_level,
    )

    # Silence noisy third-party loggers in production
    for noisy in ('uvicorn.access', 'httpx', 'httpcore', 'prophet'):
        logging.getLogger(noisy).setLevel(logging.WARNING)

    shared_processors: list = [
        # Inject correlation ID when present (set by middleware)
        _inject_correlation_id,
        structlog.contextvars.merge_contextvars,
        structlog.processors.TimeStamper(fmt='iso', utc=True),
        structlog.processors.add_log_level,
        structlog.processors.CallsiteParameterAdder(
            [
                structlog.processors.CallsiteParameter.FUNC_NAME,
                structlog.processors.CallsiteParameter.LINENO,
                structlog.processors.CallsiteParameter.MODULE,
            ]
        ),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]

    structlog.configure(
        processors=shared_processors + [
            # Forward ERROR+ events to Sentry before rendering
            _sentry_processor,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(log_level),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )


# ---------------------------------------------------------------------------
# Sentry processor — called for every log event at ERROR level or above
# ---------------------------------------------------------------------------

def _sentry_processor(logger, method: str, event_dict: dict) -> dict:  # noqa: ANN001
    """Forward ERROR+ log events to Sentry as breadcrumbs or captured events."""
    try:
        import sentry_sdk

        level = event_dict.get('level', 'info').upper()

        if level in ('ERROR', 'CRITICAL'):
            exc_info = event_dict.get('exc_info')
            with sentry_sdk.new_scope() as scope:
                scope.set_extra('log_event', event_dict.get('event', ''))
                scope.set_extra('module', event_dict.get('module', ''))
                scope.set_extra('func_name', event_dict.get('func_name', ''))
                scope.set_extra('correlation_id', event_dict.get('correlation_id', ''))
                if exc_info and exc_info is not True:
                    sentry_sdk.capture_exception(exc_info)
                elif exc_info is True:
                    sentry_sdk.capture_message(
                        event_dict.get('event', 'Unknown error'), level='error'
                    )
        else:
            # Lower levels become breadcrumbs for context on future errors
            sentry_sdk.add_breadcrumb(
                category='log',
                message=str(event_dict.get('event', '')),
                level=level.lower(),
                data={k: v for k, v in event_dict.items() if k not in ('event', 'level', '_record')},
            )
    except Exception:  # pragma: no cover — never crash the log pipeline
        pass

    return event_dict


# ---------------------------------------------------------------------------
# Correlation-ID processor
# ---------------------------------------------------------------------------

_CORRELATION_ID_CTX_KEY = 'correlation_id'


def _inject_correlation_id(logger, method: str, event_dict: dict) -> dict:  # noqa: ANN001
    """Add correlation_id from structlog context vars if present."""
    import structlog.contextvars as cv
    ctx = cv.get_contextvars()
    if _CORRELATION_ID_CTX_KEY in ctx:
        event_dict[_CORRELATION_ID_CTX_KEY] = ctx[_CORRELATION_ID_CTX_KEY]
    return event_dict


def new_correlation_id() -> str:
    return uuid.uuid4().hex
