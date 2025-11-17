from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import Depends, Header, HTTPException
from core.config import get_settings
from db.mongo import get_db
import uuid
import hashlib

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
settings = get_settings()

ALGORITHM = "HS256"

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)

def _create_token(data: dict, expires_delta: timedelta, secret: str) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode.update({"exp": expire, "iat": datetime.now(timezone.utc), "jti": str(uuid.uuid4())})
    return jwt.encode(to_encode, secret, algorithm=ALGORITHM)

def create_access_token(sub: str) -> str:
    return _create_token({"sub": sub, "type": "access"}, timedelta(minutes=settings.access_token_expire_minutes), settings.jwt_secret)

def create_refresh_token(sub: str) -> str:
    return _create_token({"sub": sub, "type": "refresh"}, timedelta(days=settings.refresh_token_expire_days), settings.jwt_refresh_secret)

def create_email_verification_token(sub: str) -> str:
    return _create_token({"sub": sub, "type": "verify"}, timedelta(minutes=settings.email_verification_expire_minutes), settings.jwt_secret)

def create_password_reset_token(sub: str) -> str:
    return _create_token({"sub": sub, "type": "reset"}, timedelta(minutes=settings.reset_token_expire_minutes), settings.jwt_secret)

def decode_token(token: str, refresh: bool = False):
    secret = settings.jwt_refresh_secret if refresh else settings.jwt_secret
    try:
        payload = jwt.decode(token, secret, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

def hash_refresh_token(token: str) -> str:
    """Store only hash of refresh token for security (rotation support)."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()

def verify_refresh_token(raw_token: str, stored_hash: str) -> bool:
    return hash_refresh_token(raw_token) == stored_hash

async def get_current_user(
    authorization: str | None = Header(default=None),
    db=Depends(get_db),
):
    """
    FastAPI dependency that validates the Bearer token and returns the Mongo user document.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token missing subject")
    user = await db["users"].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user
