from pydantic import BaseModel
from functools import lru_cache
import os
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseModel):
    mongo_uri: str = os.getenv("MONGO_URI", "mongodb://115.145.134.180:9013/")
    mongo_db: str = os.getenv("DB_NAME", "flutter_test")
    jwt_secret: str = os.getenv("JWT_SECRET", "CHANGE_ME_SECRET")
    jwt_refresh_secret: str = os.getenv("JWT_REFRESH_SECRET", "CHANGE_ME_REFRESH")
    access_token_expire_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
    refresh_token_expire_days: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))
    email_verification_expire_minutes: int = int(os.getenv("EMAIL_VERIFICATION_EXPIRE_MINUTES", "30"))
    reset_token_expire_minutes: int = int(os.getenv("RESET_TOKEN_EXPIRE_MINUTES", "30"))
    api_port: int = int(os.getenv("API_PORT", "8050"))
    cors_origins: list[str] = os.getenv("CORS_ORIGINS", "http://localhost:56000,http://127.0.0.1:56000,http://localhost:*").split(",")

    smtp_host: str | None = os.getenv("SMTP_HOST")
    smtp_port: int | None = int(os.getenv("SMTP_PORT", "0")) if os.getenv("SMTP_PORT") else None
    smtp_user: str | None = os.getenv("SMTP_USER")
    smtp_password: str | None = os.getenv("SMTP_PASSWORD")
    email_from: str | None = os.getenv("EMAIL_FROM")

@lru_cache
def get_settings() -> Settings:
    return Settings()
