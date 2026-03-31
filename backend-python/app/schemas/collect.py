from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class CollectionRecord(BaseModel):
    record_id: str | None = None
    payload: dict[str, Any]
    collected_at: datetime | None = None


class BatchCollectRequest(BaseModel):
    source: str = Field(min_length=2, max_length=120)
    records: list[CollectionRecord] = Field(min_length=1)


class BatchCollectResponse(BaseModel):
    accepted: int
    source: str
    stream_key: str
    processing_ms: float
