from fastapi import APIRouter, Request

from app.core.proxy import proxy_request


router = APIRouter(tags=['compat'])


@router.api_route('/{full_path:path}', methods=['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'])
async def compatibility_proxy(full_path: str, request: Request):
    _ = full_path
    return await proxy_request(request, request.app.state.http)
