"""
JWT authentication + RBAC permission dependency.
Mirrors behaviour of backend/src/middleware/auth.js exactly.
"""
from __future__ import annotations

from typing import Annotated, Any

import jwt
from fastapi import Depends, Header, HTTPException
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.db import get_db


class UserContext(BaseModel):
    id: int
    company_id: int
    branch_id: int | None
    role_id: int
    role_name: str
    email: str
    permissions: list[dict[str, str]]


async def get_current_user(
    authorization: Annotated[str, Header(alias='Authorization')],
    session: AsyncSession = Depends(get_db),
) -> UserContext:
    """Decode JWT, load user+role+permissions from DB."""
    settings = get_settings()

    if not authorization.startswith('Bearer '):
        raise HTTPException(status_code=401, detail='Access token is required')

    token = authorization[7:]
    try:
        payload: dict[str, Any] = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail='Access token has expired')
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail='Invalid access token')

    user_id = payload.get('userId')
    if not user_id:
        raise HTTPException(status_code=401, detail='Invalid token payload')

    result = await session.execute(
        text("""
            SELECT
                u.id,
                u.company_id,
                u.branch_id,
                u.role_id,
                u.email,
                u.is_active,
                u.deleted_at,
                r.name AS role_name,
                COALESCE(
                    json_agg(
                        json_build_object(
                            'module', p.module,
                            'action', p.action,
                            'resource', p.resource
                        )
                    ) FILTER (WHERE p.id IS NOT NULL),
                    '[]'::json
                ) AS permissions
            FROM users u
            JOIN roles r ON r.id = u.role_id
            LEFT JOIN role_permissions rp ON rp.role_id = r.id
            LEFT JOIN permissions p ON p.id = rp.permission_id
            WHERE u.id = :user_id
            GROUP BY u.id, r.name
        """),
        {'user_id': user_id},
    )
    row = result.mappings().first()

    if not row or not row['is_active'] or row['deleted_at'] is not None:
        raise HTTPException(status_code=401, detail='User account is inactive or not found')

    return UserContext(
        id=row['id'],
        company_id=row['company_id'],
        branch_id=row['branch_id'],
        role_id=row['role_id'],
        role_name=row['role_name'],
        email=row['email'],
        permissions=list(row['permissions']) if row['permissions'] else [],
    )


def require_permission(module: str, action: str):
    """
    Dependency factory — checks that the user has
    permission ``module:action``.  Admins bypass checks.
    """
    async def _check(user: UserContext = Depends(get_current_user)) -> UserContext:
        if user.role_name in ('super_admin', 'company_admin'):
            return user
        has = any(
            p.get('module') == module and p.get('action') == action
            for p in user.permissions
        )
        if not has:
            raise HTTPException(
                status_code=403,
                detail=f'Permission denied: {module}:{action}',
            )
        return user

    return _check
