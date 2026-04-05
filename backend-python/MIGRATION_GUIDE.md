# Python Migration Guide (High Performance)

This guide routes high-throughput data collection to Python first, while keeping existing APIs available through compatibility proxy.

## 1) Start existing stack

Run your normal stack so legacy API remains available on `api:3000`.

## 2) Start Python backend

```bash
docker compose -f docker-compose.python.yml up -d --build
```

## 3) Route selected traffic to Python

In your nginx server block, add this location rule before the generic `/api/` rule:

```nginx
upstream python_api_backend {
    server python-api:8000;
    keepalive 64;
}

location /api/v1/collect/ {
    proxy_pass http://python_api_backend;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 120s;
    proxy_connect_timeout 10s;
}
```

## 4) Migrate modules to native Python incrementally

- auth
- vehicles
- machines
- services
- inventory
- stores
- reports

Until each module is native, `/api/v1/*` requests are proxied to legacy backend.

## 5) Scale for throughput

- Increase `GUNICORN_WORKERS` according to CPU cores.
- Keep Redis near Python API for low latency.
- Use batch sizes aligned with payload complexity (`MAX_BATCH_SIZE`).
- Add Kafka/NATS later if event volume grows beyond Redis Streams capacity.
