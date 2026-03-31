from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env', env_file_encoding='utf-8', case_sensitive=False)

    app_name: str = Field(default='Nelna Python API', alias='APP_NAME')
    app_env: str = Field(default='development', alias='APP_ENV')
    app_port: int = Field(default=8000, alias='APP_PORT')
    log_level: str = Field(default='INFO', alias='LOG_LEVEL')

    database_url: str | None = Field(default=None, alias='DATABASE_URL')
    redis_url: str = Field(default='redis://localhost:6379/0', alias='REDIS_URL')
    legacy_api_url: str = Field(default='http://localhost:3000', alias='LEGACY_API_URL')

    # JWT — must match Node backend secret
    # No default: Pydantic raises ValidationError at startup if JWT_SECRET is unset
    jwt_secret: str = Field(alias='JWT_SECRET')
    jwt_algorithm: str = Field(default='HS256', alias='JWT_ALGORITHM')

    # Throughput tuning
    max_batch_size: int = Field(default=1000, alias='MAX_BATCH_SIZE')
    redis_stream_key: str = Field(default='nelna:collect:events', alias='REDIS_STREAM_KEY')
    proxy_timeout_seconds: float = Field(default=30.0, alias='PROXY_TIMEOUT_SECONDS')
    gunicorn_workers: int = Field(default=4, alias='GUNICORN_WORKERS')

    # Rate limiting
    rate_limit_collect: str = Field(default='200/minute', alias='RATE_LIMIT_COLLECT')

    # Stream consumer
    stream_consumer_group: str = Field(default='nelna-python-workers', alias='STREAM_CONSUMER_GROUP')
    stream_consumer_name: str = Field(default='worker-1', alias='STREAM_CONSUMER_NAME')
    stream_batch_size: int = Field(default=50, alias='STREAM_BATCH_SIZE')


@lru_cache
def get_settings() -> Settings:
    return Settings()
