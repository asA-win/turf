from pydantic_settings import BaseSettings
from pydantic import field_validator
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Turf App"
    DATABASE_URL: str = "sqlite+aiosqlite:///./turf.db"
    REDIS_URL: str = "redis://localhost:6379"
    SECRET_KEY: str = "supersecretkey_turf_app_2026_production_secure_key_32bytes"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # Cloudinary / Local Upload Config
    CLOUDINARY_CLOUD_NAME: str = "demo"
    CLOUDINARY_API_KEY: str = "demo_key"
    CLOUDINARY_API_SECRET: str = "demo_secret"
    UPLOAD_DIR: str = "uploads"

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def ensure_async_prefix(cls, v: str) -> str:
        if v:
            v = v.strip().strip("'\"")
            if v.startswith("postgres://"):
                v = v.replace("postgres://", "postgresql+asyncpg://", 1)
            elif v.startswith("postgresql://"):
                v = v.replace("postgresql://", "postgresql+asyncpg://", 1)
            elif v.startswith("sqlite://"):
                v = v.replace("sqlite://", "sqlite+aiosqlite://", 1)

            # asyncpg accepts ssl=... instead of sslmode=...
            if "sslmode=" in v:
                v = v.replace("sslmode=", "ssl=")
        return v

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"

settings = Settings()

