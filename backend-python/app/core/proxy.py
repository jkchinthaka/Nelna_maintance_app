from typing import Iterable

import httpx
from fastapi import Request, Response

from app.core.config import get_settings


_HOP_BY_HOP = {
    'connection',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailers',
    'transfer-encoding',
    'upgrade',
    'host',
    'content-length',
}


def _filtered_headers(headers: Iterable[tuple[str, str]]) -> dict[str, str]:
    return {k: v for k, v in headers if k.lower() not in _HOP_BY_HOP}


async def proxy_request(request: Request, client: httpx.AsyncClient) -> Response:
    settings = get_settings()
    upstream = f"{settings.legacy_api_url.rstrip('/')}{request.url.path}"
    if request.url.query:
        upstream = f"{upstream}?{request.url.query}"

    body = await request.body()
    proxied = await client.request(
        request.method,
        upstream,
        content=body,
        headers=_filtered_headers(request.headers.items()),
    )

    return Response(
        content=proxied.content,
        status_code=proxied.status_code,
        headers=_filtered_headers(proxied.headers.items()),
        media_type=proxied.headers.get('content-type'),
    )
