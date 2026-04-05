import multiprocessing
import os

bind = f"0.0.0.0:{os.getenv('APP_PORT', '8000')}"
workers = int(os.getenv('GUNICORN_WORKERS', max(2, multiprocessing.cpu_count())))
worker_class = "uvicorn.workers.UvicornWorker"
threads = int(os.getenv('GUNICORN_THREADS', '1'))
worker_connections = int(os.getenv('GUNICORN_WORKER_CONNECTIONS', '2000'))
timeout = int(os.getenv('GUNICORN_TIMEOUT', '60'))
keepalive = int(os.getenv('GUNICORN_KEEPALIVE', '5'))
accesslog = '-'
errorlog = '-'
