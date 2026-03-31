"""
AI / ML API Routes — Nelna Maintenance System
=============================================
All endpoints are prefixed with /api/v1/ai (see router.py).

Endpoints:
  POST /ai/maintenance/predict   — Predictive maintenance risk
  POST /ai/inventory/forecast    — Inventory demand forecast
  POST /ai/anomaly/detect        — Anomaly detection on telemetry
  POST /ai/assistant/ask         — LLM maintenance assistant
  POST /ai/image/assess          — Image-based condition assessment
"""
from __future__ import annotations

from typing import Annotated, Any

from fastapi import APIRouter, Depends, File, Form, Query, Request, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import UserContext, require_permission
from app.services import predictions as svc

router = APIRouter(prefix='/ai', tags=['AI/ML'])

_MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB


# ────────────────────────────────────────────────────────────────────────────
# Schemas
# ────────────────────────────────────────────────────────────────────────────

class MaintenancePredictRequest(BaseModel):
    asset_type: str = Field(
        description="One of: vehicle, machine, asset",
        examples=["vehicle"],
    )
    asset_id: int = Field(description="Primary key of the asset", examples=[42])
    horizon_days: int = Field(
        default=90,
        ge=1,
        le=365,
        description="Look-ahead window in days",
    )


class InventoryForecastRequest(BaseModel):
    product_id: int = Field(description="Primary key of the product", examples=[7])
    periods: int = Field(
        default=30,
        ge=1,
        le=365,
        description="Number of future days to forecast",
    )


class AnomalyDetectRequest(BaseModel):
    events: list[dict[str, Any]] = Field(
        description=(
            "List of numeric event dicts from the Redis stream. "
            "Each dict must contain at least one numeric field (e.g. 'value', 'temperature')."
        ),
        min_length=1,
        max_length=5000,
    )
    contamination: float = Field(
        default=0.05,
        ge=0.001,
        le=0.5,
        description="Expected fraction of anomalies in the dataset",
    )


class AssistantAskRequest(BaseModel):
    question: str = Field(
        description="Natural-language maintenance question",
        min_length=3,
        max_length=2000,
        examples=["What maintenance should I schedule for vehicle 42 next month?"],
    )
    asset_type: str | None = Field(
        default=None,
        description="Optional: vehicle | machine | asset",
    )
    asset_id: int | None = Field(
        default=None,
        description="Optional: asset ID for context injection",
    )
    provider: str = Field(
        default="openai",
        description="LLM provider: openai | gemini",
    )


# ────────────────────────────────────────────────────────────────────────────
# 1. Predictive Maintenance
# ────────────────────────────────────────────────────────────────────────────

@router.post(
    '/maintenance/predict',
    summary='Predict maintenance needs for an asset',
    response_description='Failure probability and predicted next service date',
)
async def predict_maintenance(
    body: MaintenancePredictRequest,
    session: AsyncSession = Depends(get_db),
    user: UserContext = Depends(require_permission('reports', 'read')),
) -> dict[str, Any]:
    """
    Uses a RandomForestClassifier trained on historical `service_requests`
    to predict the probability that a given asset will require maintenance
    within `horizon_days`.
    """
    result = await svc.predict_maintenance(
        session=session,
        asset_type=body.asset_type,
        asset_id=body.asset_id,
        horizon_days=body.horizon_days,
    )
    result["asset_type"] = body.asset_type
    return result


# ────────────────────────────────────────────────────────────────────────────
# 2. Inventory Demand Forecasting
# ────────────────────────────────────────────────────────────────────────────

@router.post(
    '/inventory/forecast',
    summary='Forecast inventory demand for a product',
    response_description='Daily demand forecast with confidence intervals',
)
async def forecast_inventory(
    body: InventoryForecastRequest,
    session: AsyncSession = Depends(get_db),
    user: UserContext = Depends(require_permission('inventory', 'read')),
) -> dict[str, Any]:
    """
    Uses Facebook Prophet on `stock_movements` data to forecast daily
    demand and recommend a reorder quantity for the given horizon.
    """
    return await svc.forecast_inventory(
        session=session,
        product_id=body.product_id,
        periods=body.periods,
    )


# ────────────────────────────────────────────────────────────────────────────
# 3. Anomaly Detection
# ────────────────────────────────────────────────────────────────────────────

@router.post(
    '/anomaly/detect',
    summary='Detect anomalies in a batch of telemetry events',
    response_description='List of anomalous events with scores',
)
async def detect_anomalies(
    body: AnomalyDetectRequest,
    user: UserContext = Depends(require_permission('reports', 'read')),
) -> dict[str, Any]:
    """
    Runs IsolationForest on a batch of numeric events (e.g. from the Redis
    telemetry stream). Returns events classified as anomalous along with
    their anomaly scores.
    """
    return await svc.detect_anomalies(
        redis_events=body.events,
        contamination=body.contamination,
    )


# ────────────────────────────────────────────────────────────────────────────
# 4. LLM Maintenance Assistant
# ────────────────────────────────────────────────────────────────────────────

@router.post(
    '/assistant/ask',
    summary='Ask the AI maintenance assistant a question',
    response_description='LLM-generated maintenance advice with DB context',
)
async def ask_assistant(
    body: AssistantAskRequest,
    session: AsyncSession = Depends(get_db),
    user: UserContext = Depends(require_permission('reports', 'read')),
) -> dict[str, Any]:
    """
    Forwards a natural-language question to OpenAI GPT-4o-mini or Google
    Gemini, injecting relevant service history from the database as context.
    Set provider to "openai" (default) or "gemini".
    """
    return await svc.llm_assistant(
        session=session,
        question=body.question,
        asset_type=body.asset_type,
        asset_id=body.asset_id,
        provider=body.provider,
    )


# ────────────────────────────────────────────────────────────────────────────
# 5. Image-Based Condition Assessment
# ────────────────────────────────────────────────────────────────────────────

@router.post(
    '/image/assess',
    summary='Assess asset condition from an uploaded image',
    response_description='Condition label (good/fair/poor/critical) with confidence',
)
async def assess_image(
    file: UploadFile = File(description="Asset image (JPEG, PNG, WEBP — max 10 MB)"),
    use_cloud_vision: bool = Form(
        default=False,
        description="Set true to use Google Cloud Vision instead of local EfficientNet model",
    ),
    user: UserContext = Depends(require_permission('assets', 'read')),
) -> dict[str, Any]:
    """
    Assesses the physical condition of an asset from an uploaded image.

    - **Local mode** (default): EfficientNet-B0 (torchvision, ImageNet weights)
    - **Cloud mode**: Google Cloud Vision label detection (requires GOOGLE_VISION_API_KEY)

    Returns one of four condition labels: `good`, `fair`, `poor`, `critical`.
    """
    allowed_types = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
    if file.content_type not in allowed_types:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported media type '{file.content_type}'. Allowed: {allowed_types}",
        )

    image_bytes = await file.read()
    if len(image_bytes) > _MAX_IMAGE_BYTES:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=413,
            detail=f"Image exceeds maximum size of {_MAX_IMAGE_BYTES // (1024*1024)} MB",
        )

    return await svc.assess_image_condition(
        image_bytes=image_bytes,
        content_type=file.content_type or "image/jpeg",
        use_cloud_vision=use_cloud_vision,
    )
