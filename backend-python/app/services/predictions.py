"""
AI/ML Service Layer — Nelna Maintenance System
===============================================
Provides five core capabilities:

  1. Predictive Maintenance      — RandomForest on historical service records
  2. Inventory Demand Forecasting — Prophet time-series on stock movements
  3. Anomaly Detection           — IsolationForest on Redis stream events
  4. LLM Maintenance Assistant   — OpenAI / Gemini with DB context
  5. Image Condition Assessment  — EfficientNet-B0 (torchvision) or Vision API

All I/O is async-safe; CPU-bound ML work is dispatched to a thread pool via
asyncio.to_thread so the FastAPI event loop is never blocked.

All errors are:
  • Logged via structlog with full context
  • Captured in Sentry with ML-specific tags when a DSN is configured
  • Counted in Prometheus (nelna_ai_predictions_total{outcome="error"})
"""
from __future__ import annotations

import asyncio
import base64
import io
import json
import time
from datetime import date, datetime, timedelta, timezone
from typing import Any

import numpy as np
import structlog
from fastapi import HTTPException
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.metrics import AI_PREDICTION_LATENCY, AI_PREDICTION_TOTAL, ANOMALY_ALERTS_TOTAL

log = structlog.get_logger(__name__)


# ────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────

def _require_setting(value: str | None, name: str) -> str:
    if not value:
        raise HTTPException(
            status_code=503,
            detail=f"Feature unavailable: {name} is not configured.",
        )
    return value


def _capture_ml_error(feature: str, exc: Exception, **extra: Any) -> None:
    """Send an ML prediction error to Sentry with feature-specific tags."""
    settings = get_settings()
    if not settings.sentry_dsn:
        return
    try:
        import sentry_sdk
        with sentry_sdk.new_scope() as scope:
            scope.set_tag('ml_feature', feature)
            for key, value in extra.items():
                scope.set_extra(key, value)
            sentry_sdk.capture_exception(exc)
    except Exception:
        pass


# ============================================================================
# 1. PREDICTIVE MAINTENANCE
# ============================================================================

async def predict_maintenance(
    session: AsyncSession,
    asset_type: str,           # "vehicle" | "machine" | "asset"
    asset_id: int,
    horizon_days: int = 90,
) -> dict[str, Any]:
    """
    Train a RandomForestClassifier on historical service records for the
    given asset type and predict whether maintenance will be needed within
    `horizon_days`.
    """
    table_map = {
        "vehicle": ("vehicles", "vehicle_id"),
        "machine": ("machines", "machine_id"),
        "asset":   ("assets",   "asset_id"),
    }
    if asset_type not in table_map:
        raise HTTPException(status_code=400, detail=f"Unknown asset_type '{asset_type}'")

    _, fk_col = table_map[asset_type]

    t0 = time.perf_counter()
    try:
        rows = await session.execute(
            text(f"""
                SELECT
                    sr.id,
                    sr.{fk_col}                        AS asset_id,
                    EXTRACT(EPOCH FROM (sr.updated_at - sr.created_at)) / 86400 AS resolution_days,
                    EXTRACT(DOY  FROM sr.created_at)   AS day_of_year,
                    EXTRACT(DOW  FROM sr.created_at)   AS day_of_week,
                    EXTRACT(MONTH FROM sr.created_at)  AS month,
                    COALESCE(sr.total_cost, 0)          AS cost,
                    CASE WHEN sr.status = 'COMPLETED' THEN 1 ELSE 0 END AS completed,
                    LAG(sr.created_at) OVER (
                        PARTITION BY sr.{fk_col}
                        ORDER BY sr.created_at
                    ) AS prev_service_date,
                    EXTRACT(EPOCH FROM (
                        sr.created_at - LAG(sr.created_at) OVER (
                            PARTITION BY sr.{fk_col} ORDER BY sr.created_at
                        )
                    )) / 86400 AS days_since_last_service
                FROM service_requests sr
                WHERE sr.{fk_col} IS NOT NULL
                  AND sr.deleted_at IS NULL
                ORDER BY sr.{fk_col}, sr.created_at
            """)
        )
        records = rows.mappings().all()

        if len(records) < 5:
            AI_PREDICTION_TOTAL.labels(feature='maintenance', outcome='insufficient_data').inc()
            return {
                "asset_id": asset_id,
                "asset_type": asset_type,
                "failure_probability": None,
                "predicted_next_service": None,
                "confidence": "insufficient_data",
                "top_features": [],
                "training_samples": len(records),
                "message": "Not enough historical data (need ≥ 5 service records).",
            }

        result = await asyncio.to_thread(
            _run_maintenance_model,
            records=list(records),
            asset_id=asset_id,
            horizon_days=horizon_days,
        )
        AI_PREDICTION_TOTAL.labels(feature='maintenance', outcome='success').inc()
        AI_PREDICTION_LATENCY.labels(feature='maintenance').observe(time.perf_counter() - t0)
        return result

    except HTTPException:
        raise
    except Exception as exc:
        AI_PREDICTION_TOTAL.labels(feature='maintenance', outcome='error').inc()
        log.error('Predictive maintenance failed', exc_info=exc, asset_type=asset_type, asset_id=asset_id)
        _capture_ml_error('maintenance', exc, asset_type=asset_type, asset_id=asset_id)
        raise HTTPException(status_code=500, detail='Predictive maintenance model failed') from exc


def _run_maintenance_model(
    records: list[dict],
    asset_id: int,
    horizon_days: int,
) -> dict[str, Any]:
    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import train_test_split
    from sklearn.preprocessing import StandardScaler

    df = pd.DataFrame(records)
    df = df.dropna(subset=["days_since_last_service"])

    feature_cols = ["day_of_year", "day_of_week", "month", "cost", "days_since_last_service", "resolution_days"]
    df[feature_cols] = df[feature_cols].fillna(0)

    df["needs_service_soon"] = (df["days_since_last_service"] <= horizon_days).astype(int)

    X = df[feature_cols].values
    y = df["needs_service_soon"].values

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    if len(X) < 10:
        X_train, X_test, y_train, y_test = X_scaled, X_scaled, y, y
    else:
        X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, random_state=42)

    clf = RandomForestClassifier(n_estimators=100, random_state=42, class_weight="balanced")
    clf.fit(X_train, y_train)

    asset_rows = df[df["asset_id"] == asset_id]
    if asset_rows.empty:
        last_row = df.iloc[-1]
    else:
        last_row = asset_rows.iloc[-1]

    X_pred = scaler.transform([last_row[feature_cols].values])
    proba = clf.predict_proba(X_pred)[0]
    failure_prob = float(proba[1]) if 1 in clf.classes_ else 0.0

    importances = clf.feature_importances_
    top_features = [feature_cols[i] for i in np.argsort(importances)[::-1][:3]]

    days_since = float(last_row["days_since_last_service"] or 0)
    predicted_next = (date.today() + timedelta(days=max(0, horizon_days - days_since))).isoformat()

    if len(records) >= 30:
        confidence = "high"
    elif len(records) >= 10:
        confidence = "medium"
    else:
        confidence = "low"

    return {
        "asset_id": asset_id,
        "asset_type": "unknown",
        "failure_probability": round(failure_prob, 4),
        "predicted_next_service": predicted_next,
        "confidence": confidence,
        "top_features": top_features,
        "training_samples": len(records),
    }


# ============================================================================
# 2. INVENTORY DEMAND FORECASTING
# ============================================================================

async def forecast_inventory(
    session: AsyncSession,
    product_id: int,
    periods: int = 30,
) -> dict[str, Any]:
    """
    Use Prophet to forecast daily stock demand for a product.
    """
    t0 = time.perf_counter()
    try:
        rows = await session.execute(
            text("""
                SELECT
                    DATE(sm.created_at) AS ds,
                    SUM(ABS(sm.quantity)) AS y
                FROM stock_movements sm
                WHERE sm.product_id = :pid
                  AND sm.movement_type IN ('STOCK_OUT', 'ADJUSTMENT')
                  AND sm.created_at >= NOW() - INTERVAL '2 years'
                GROUP BY DATE(sm.created_at)
                ORDER BY ds
            """),
            {"pid": product_id},
        )
        records = rows.mappings().all()

        if len(records) < 10:
            AI_PREDICTION_TOTAL.labels(feature='inventory', outcome='insufficient_data').inc()
            return {
                "product_id": product_id,
                "forecast_periods_days": periods,
                "forecast": [],
                "recommended_reorder_qty": None,
                "training_samples": len(records),
                "message": "Not enough movement history (need ≥ 10 days of data).",
            }

        result = await asyncio.to_thread(
            _run_prophet_forecast,
            records=list(records),
            product_id=product_id,
            periods=periods,
        )
        AI_PREDICTION_TOTAL.labels(feature='inventory', outcome='success').inc()
        AI_PREDICTION_LATENCY.labels(feature='inventory').observe(time.perf_counter() - t0)
        return result

    except HTTPException:
        raise
    except Exception as exc:
        AI_PREDICTION_TOTAL.labels(feature='inventory', outcome='error').inc()
        log.error('Inventory forecast failed', exc_info=exc, product_id=product_id)
        _capture_ml_error('inventory', exc, product_id=product_id)
        raise HTTPException(status_code=500, detail='Inventory forecast model failed') from exc


def _run_prophet_forecast(
    records: list[dict],
    product_id: int,
    periods: int,
) -> dict[str, Any]:
    import pandas as pd
    from prophet import Prophet  # type: ignore[import-untyped]

    df = pd.DataFrame(records)
    df["ds"] = pd.to_datetime(df["ds"])
    df["y"] = df["y"].astype(float)

    model = Prophet(
        yearly_seasonality=True,
        weekly_seasonality=True,
        daily_seasonality=False,
        interval_width=0.8,
    )
    model.fit(df)

    future = model.make_future_dataframe(periods=periods)
    forecast = model.predict(future)

    future_only = forecast.tail(periods)[["ds", "yhat", "yhat_lower", "yhat_upper"]]
    future_only["yhat"] = future_only["yhat"].clip(lower=0)
    future_only["yhat_lower"] = future_only["yhat_lower"].clip(lower=0)
    future_only["yhat_upper"] = future_only["yhat_upper"].clip(lower=0)

    forecast_list = [
        {
            "ds": row["ds"].strftime("%Y-%m-%d"),
            "yhat": round(float(row["yhat"]), 2),
            "yhat_lower": round(float(row["yhat_lower"]), 2),
            "yhat_upper": round(float(row["yhat_upper"]), 2),
        }
        for _, row in future_only.iterrows()
    ]

    recommended_qty = int(np.ceil(future_only["yhat_upper"].sum()))

    return {
        "product_id": product_id,
        "forecast_periods_days": periods,
        "forecast": forecast_list,
        "recommended_reorder_qty": recommended_qty,
        "training_samples": len(records),
    }


# ============================================================================
# 3. ANOMALY DETECTION (Redis stream events)
# ============================================================================

async def detect_anomalies(
    redis_events: list[dict[str, Any]],
    contamination: float = 0.05,
) -> dict[str, Any]:
    """
    Run IsolationForest on a batch of numeric sensor / telemetry events
    extracted from the Redis stream.
    """
    if not redis_events:
        return {
            "total_events": 0,
            "anomaly_count": 0,
            "anomalies": [],
            "contamination_used": contamination,
        }

    t0 = time.perf_counter()
    try:
        result = await asyncio.to_thread(
            _run_isolation_forest,
            events=redis_events,
            contamination=contamination,
        )
        anomaly_count: int = result.get('anomaly_count', 0)
        AI_PREDICTION_TOTAL.labels(feature='anomaly', outcome='success').inc()
        AI_PREDICTION_LATENCY.labels(feature='anomaly').observe(time.perf_counter() - t0)
        if anomaly_count > 0:
            ANOMALY_ALERTS_TOTAL.labels(stream_key='nelna:collect:events').inc(anomaly_count)
            log.warning('Anomalies detected', count=anomaly_count, total_events=len(redis_events))
        return result

    except HTTPException:
        raise
    except Exception as exc:
        AI_PREDICTION_TOTAL.labels(feature='anomaly', outcome='error').inc()
        log.error('Anomaly detection failed', exc_info=exc, event_count=len(redis_events))
        _capture_ml_error('anomaly', exc, event_count=len(redis_events))
        raise HTTPException(status_code=500, detail='Anomaly detection failed') from exc


def _run_isolation_forest(
    events: list[dict[str, Any]],
    contamination: float,
) -> dict[str, Any]:
    import pandas as pd
    from sklearn.ensemble import IsolationForest
    from sklearn.preprocessing import StandardScaler

    df = pd.DataFrame(events)
    record_ids = df.get("record_id", pd.Series(range(len(df)))).tolist()

    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    if not numeric_cols:
        raise HTTPException(status_code=400, detail="No numeric fields found in event payload.")

    X = df[numeric_cols].fillna(0).values
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    clf = IsolationForest(
        contamination=contamination,
        random_state=42,
        n_estimators=200,
    )
    preds = clf.fit_predict(X_scaled)
    scores = clf.decision_function(X_scaled)

    anomalies = []
    for i, (pred, score) in enumerate(zip(preds, scores)):
        if pred == -1:
            anomaly_record = {"record_id": record_ids[i], "anomaly_score": round(float(score), 6)}
            for col in numeric_cols:
                anomaly_record[col] = float(df[numeric_cols].iloc[i][col])
            anomalies.append(anomaly_record)

    return {
        "total_events": len(events),
        "anomaly_count": len(anomalies),
        "anomalies": anomalies,
        "contamination_used": contamination,
    }


# ============================================================================
# 4. LLM MAINTENANCE ASSISTANT
# ============================================================================

async def llm_assistant(
    session: AsyncSession,
    question: str,
    asset_type: str | None = None,
    asset_id: int | None = None,
    provider: str = "openai",
) -> dict[str, Any]:
    """
    Answer a maintenance question using an LLM (OpenAI or Gemini),
    injecting relevant DB context (recent service records, asset details).
    """
    settings = get_settings()
    context_data: dict[str, Any] = {}

    t0 = time.perf_counter()
    try:
        if asset_type and asset_id:
            fk_map = {"vehicle": "vehicle_id", "machine": "machine_id", "asset": "asset_id"}
            fk = fk_map.get(asset_type)
            if fk:
                rows = await session.execute(
                    text(f"""
                        SELECT
                            sr.id,
                            sr.status,
                            sr.description,
                            sr.priority,
                            COALESCE(sr.total_cost, 0) AS cost,
                            sr.created_at
                        FROM service_requests sr
                        WHERE sr.{fk} = :aid
                          AND sr.deleted_at IS NULL
                        ORDER BY sr.created_at DESC
                        LIMIT 10
                    """),
                    {"aid": asset_id},
                )
                recent = rows.mappings().all()
                context_data["recent_service_records"] = [
                    {
                        "id": r["id"],
                        "status": r["status"],
                        "description": r["description"],
                        "priority": r["priority"],
                        "cost": float(r["cost"]),
                        "created_at": r["created_at"].isoformat() if r["created_at"] else None,
                    }
                    for r in recent
                ]

        system_prompt = (
            "You are an expert maintenance engineer assistant for Nelna Maintenance System, "
            "a fleet and asset management platform. Answer questions concisely and practically. "
            "When given service history, use it to provide specific advice. "
            "Always recommend safety-first approaches."
        )

        context_str = ""
        if context_data:
            context_str = f"\n\nContext from the maintenance database:\n{json.dumps(context_data, indent=2)}"

        full_question = question + context_str

        if provider == "gemini":
            answer, model_name = await asyncio.to_thread(
                _call_gemini, system_prompt, full_question, settings.gemini_api_key
            )
        else:
            answer, model_name = await asyncio.to_thread(
                _call_openai, system_prompt, full_question, settings.openai_api_key
            )

        AI_PREDICTION_TOTAL.labels(feature='assistant', outcome='success').inc()
        AI_PREDICTION_LATENCY.labels(feature='assistant').observe(time.perf_counter() - t0)
        return {
            "answer": answer,
            "context_used": context_data,
            "provider": provider,
            "model": model_name,
        }

    except HTTPException:
        raise
    except Exception as exc:
        AI_PREDICTION_TOTAL.labels(feature='assistant', outcome='error').inc()
        log.error('LLM assistant failed', exc_info=exc, provider=provider, asset_type=asset_type)
        _capture_ml_error('assistant', exc, provider=provider, asset_type=asset_type, asset_id=asset_id)
        raise HTTPException(status_code=500, detail='LLM assistant request failed') from exc


def _call_openai(system_prompt: str, question: str, api_key: str | None) -> tuple[str, str]:
    _require_setting(api_key, "OPENAI_API_KEY")
    from openai import OpenAI  # type: ignore[import-untyped]

    client = OpenAI(api_key=api_key)
    model = "gpt-4o-mini"
    resp = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": question},
        ],
        max_tokens=1024,
        temperature=0.3,
    )
    return resp.choices[0].message.content or "", model


def _call_gemini(system_prompt: str, question: str, api_key: str | None) -> tuple[str, str]:
    _require_setting(api_key, "GEMINI_API_KEY")
    import google.generativeai as genai  # type: ignore[import-untyped]

    genai.configure(api_key=api_key)
    model_name = "gemini-2.0-flash"
    model = genai.GenerativeModel(
        model_name=model_name,
        system_instruction=system_prompt,
    )
    resp = model.generate_content(question)
    return resp.text or "", model_name


# ============================================================================
# 5. IMAGE CONDITION ASSESSMENT
# ============================================================================

_CONDITION_LABELS = ["good", "fair", "poor", "critical"]

_EFFICIENTNET_MODEL: Any = None
_EFFICIENTNET_TRANSFORM: Any = None


def _load_efficientnet() -> tuple[Any, Any]:
    global _EFFICIENTNET_MODEL, _EFFICIENTNET_TRANSFORM
    if _EFFICIENTNET_MODEL is not None:
        return _EFFICIENTNET_MODEL, _EFFICIENTNET_TRANSFORM

    import torch
    import torchvision.models as models
    import torchvision.transforms as T

    model = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.IMAGENET1K_V1)
    model.eval()

    transform = T.Compose([
        T.Resize((224, 224)),
        T.ToTensor(),
        T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    _EFFICIENTNET_MODEL = model
    _EFFICIENTNET_TRANSFORM = transform
    return model, transform


async def assess_image_condition(
    image_bytes: bytes,
    content_type: str = "image/jpeg",
    use_cloud_vision: bool = False,
) -> dict[str, Any]:
    """
    Assess the physical condition of an asset/machine from an uploaded image.
    """
    settings = get_settings()
    t0 = time.perf_counter()
    try:
        if use_cloud_vision and settings.google_vision_api_key:
            result = await asyncio.to_thread(
                _assess_with_cloud_vision, image_bytes, settings.google_vision_api_key
            )
        else:
            result = await asyncio.to_thread(_assess_with_efficientnet, image_bytes)

        AI_PREDICTION_TOTAL.labels(feature='image', outcome='success').inc()
        AI_PREDICTION_LATENCY.labels(feature='image').observe(time.perf_counter() - t0)

        if result.get('condition') in ('poor', 'critical'):
            log.warning(
                'Asset condition assessment',
                condition=result['condition'],
                confidence=result.get('confidence'),
                method=result.get('method'),
            )
        return result

    except HTTPException:
        raise
    except Exception as exc:
        AI_PREDICTION_TOTAL.labels(feature='image', outcome='error').inc()
        log.error('Image condition assessment failed', exc_info=exc)
        _capture_ml_error('image', exc)
        raise HTTPException(status_code=500, detail='Image condition assessment failed') from exc


def _assess_with_efficientnet(image_bytes: bytes) -> dict[str, Any]:
    import torch
    from PIL import Image

    try:
        model, transform = _load_efficientnet()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        tensor = transform(image).unsqueeze(0)

        with torch.no_grad():
            logits = model(tensor)
            probs = torch.softmax(logits, dim=1).squeeze()

        top_prob, top_idx = probs.topk(5)
        top_probs = top_prob.tolist()
        top_indices = top_idx.tolist()

        # Map ImageNet indices to condition heuristics:
        # This uses a simple heuristic: "rusty", "dirty", "broken" class indices
        # map to degraded conditions. For production, fine-tune on domain data.
        rust_indices = {401, 449, 469, 542, 663}      # rust-like classes
        broken_indices = {419, 813, 874, 912, 936}    # broken/damaged
        dirty_indices = {409, 476, 488, 833}           # stained/dirty

        degradation_score = 0.0
        for prob, idx in zip(top_probs, top_indices):
            if idx in broken_indices:
                degradation_score += prob * 3
            elif idx in rust_indices:
                degradation_score += prob * 2
            elif idx in dirty_indices:
                degradation_score += prob * 1

        if degradation_score >= 0.6:
            condition = "critical"
            confidence = min(0.99, degradation_score)
        elif degradation_score >= 0.35:
            condition = "poor"
            confidence = min(0.95, 0.5 + degradation_score)
        elif degradation_score >= 0.15:
            condition = "fair"
            confidence = 0.70
        else:
            condition = "good"
            confidence = float(top_probs[0]) if top_probs else 0.8

        return {
            "condition": condition,
            "confidence": round(confidence, 4),
            "details": [f"Top class indices detected: {top_indices[:3]}"],
            "method": "local_efficientnet",
        }
    except Exception as exc:
        log.warning("EfficientNet inference failed", error=str(exc))
        raise HTTPException(status_code=500, detail=f"Image assessment failed: {exc}") from exc


def _assess_with_cloud_vision(image_bytes: bytes, api_key: str) -> dict[str, Any]:
    import httpx

    encoded = base64.b64encode(image_bytes).decode("utf-8")
    payload = {
        "requests": [
            {
                "image": {"content": encoded},
                "features": [
                    {"type": "LABEL_DETECTION", "maxResults": 20},
                    {"type": "OBJECT_LOCALIZATION", "maxResults": 10},
                ],
            }
        ]
    }

    resp = httpx.post(
        f"https://vision.googleapis.com/v1/images:annotate?key={api_key}",
        json=payload,
        timeout=15.0,
    )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Cloud Vision API error: {resp.text}")

    data = resp.json()
    annotations = data.get("responses", [{}])[0]

    labels = [l["description"].lower() for l in annotations.get("labelAnnotations", [])]
    objects = [o["name"].lower() for o in annotations.get("localizedObjectAnnotations", [])]
    all_detected = labels + objects

    critical_keywords = {"rust", "crack", "broken", "damaged", "corroded", "leaking", "burnt", "shattered"}
    poor_keywords = {"worn", "dirty", "degraded", "scratched", "dented", "faded", "stained"}
    fair_keywords = {"used", "old", "minor", "small", "slight"}

    score = 0
    matched_details = []
    for item in all_detected:
        for kw in critical_keywords:
            if kw in item:
                score += 3
                matched_details.append(f"critical signal: {item!r}")
        for kw in poor_keywords:
            if kw in item:
                score += 2
                matched_details.append(f"poor signal: {item!r}")
        for kw in fair_keywords:
            if kw in item:
                score += 1
                matched_details.append(f"fair signal: {item!r}")

    if score >= 6:
        condition, confidence = "critical", 0.92
    elif score >= 4:
        condition, confidence = "poor", 0.80
    elif score >= 2:
        condition, confidence = "fair", 0.70
    else:
        condition, confidence = "good", 0.85

    return {
        "condition": condition,
        "confidence": confidence,
        "details": matched_details[:10] if matched_details else all_detected[:5],
        "method": "google_cloud_vision",
    }
