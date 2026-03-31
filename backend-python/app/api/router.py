from fastapi import APIRouter

from app.api.routes.collect import router as collect_router
from app.api.routes.compat import router as compat_router
from app.api.routes.health import router as health_router
from app.api.routes.inventory import router as inventory_router


api_router = APIRouter(prefix='/api/v1')

api_router.include_router(health_router)
api_router.include_router(collect_router)
api_router.include_router(inventory_router)
# compat must be last — it is a catch-all proxy
api_router.include_router(compat_router)
