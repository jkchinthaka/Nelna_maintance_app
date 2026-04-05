# Nelna Python High-Performance Backend

This service is the migration target for moving the backend from Node.js to Python with minimal downtime.

## What is implemented

- FastAPI async backend optimized for high request throughput.
- ORJSON response pipeline for faster serialization.
- Redis stream-based batch data collection endpoint.
- HTTP connection pooling and compatibility proxy to legacy Node API.
- Health endpoint with optional database check.

## High-performance endpoints

- `POST /api/v1/collect/batch`
- `GET /api/v1/health`

All other `/api/v1/*` routes are proxied to the legacy backend until migrated.

## Run locally

1. Install Python 3.12+
2. Create virtual environment and install dependencies:
   - `pip install -r requirements.txt`
3. Copy `.env.example` to `.env` and adjust values.
4. Start server:
   - `uvicorn app.main:app --host 0.0.0.0 --port 8000`

## Run with Docker

- Ensure main stack network exists (`nelna_network` from root compose).
- Run:
  - `docker compose -f docker-compose.python.yml up -d --build`

## Migration strategy

1. Keep frontend pointed to same API base path.
2. Route traffic to Python service for migrated high-throughput endpoints first.
3. Move module-by-module business logic from Node to Python.
4. Once all modules are native in Python, remove compatibility proxy.
