from fastapi import APIRouter, Depends, HTTPException, Header
from schemas.auth import (
    SignupRequest,
    LoginRequest,
    RefreshRequest,
    PasswordResetStartRequest,
    PasswordResetFinishRequest,
    EmailVerifyRequest,
    PasswordChangeRequest,
)
from schemas.user import TokenPair
from db.mongo import get_db
from core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    create_email_verification_token,
    create_password_reset_token,
    decode_token,
    hash_refresh_token,
    verify_refresh_token,
)
from datetime import datetime, timezone
import uuid

# NOTE: codes 컬렉션과 기본 그룹 생성을 signup에서 처리하여 Flutter 쪽 로직 단순화.

router = APIRouter(prefix="/auth", tags=["auth"])

async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")

@router.post("/signup", response_model=TokenPair)
async def signup(payload: SignupRequest, db=Depends(get_db)):
    existing = await db["users"].find_one({"email": payload.email})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    # 코드 검증 임시 비활성화 (개발용)
    # if payload.code:
    #     code_doc = await db["codes"].find_one({"_id": payload.code, "valid": True})
    #     if not code_doc:
    #         raise HTTPException(status_code=400, detail="Invalid or expired code")

    user_id = f"user_{uuid.uuid4().hex[:8]}"
    doc = {
        "_id": user_id,
        "email": payload.email,
        "name": payload.name,
        "gender": payload.gender,
        "code": payload.code,
        "password_hash": hash_password(payload.password),
        "survey_completed": False,
        "worry_groups": [
            {
                "group_id": "1",
                "group_title": "기본그룹",
                "group_contents": "기본그룹 입니다",
                "created_at": datetime.now(timezone.utc),
            }
        ],
        "relaxation_tasks": [],
        "surveys": [],
        "custom_tags": [],
        "practice_sessions": [],
        "email_verified": False,
        "created_at": datetime.now(timezone.utc),
    }
    await db["users"].insert_one(doc)

    # Refresh token 저장 (hash)
    refresh_raw = create_refresh_token(user_id)
    await db["users"].update_one({"_id": user_id}, {"$set": {"refresh_hash": hash_refresh_token(refresh_raw), "refresh_issued_at": datetime.now(timezone.utc)}})
    return TokenPair(access_token=create_access_token(user_id), refresh_token=refresh_raw)

@router.post("/login", response_model=TokenPair)
async def login(payload: LoginRequest, db=Depends(get_db)):
    user = await db["users"].find_one({"email": payload.email})
    if not user or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    refresh_raw = create_refresh_token(user["_id"])
    await db["users"].update_one({"_id": user["_id"]}, {"$set": {"refresh_hash": hash_refresh_token(refresh_raw), "refresh_issued_at": datetime.now(timezone.utc)}})
    return TokenPair(access_token=create_access_token(user["_id"]), refresh_token=refresh_raw)

@router.post("/refresh", response_model=TokenPair)
async def refresh(payload: RefreshRequest, db=Depends(get_db)):
    decoded = decode_token(payload.refresh_token, refresh=True)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    sub = decoded.get("sub")
    user = await db["users"].find_one({"_id": sub})
    if not user or "refresh_hash" not in user:
        raise HTTPException(status_code=401, detail="Invalid refresh state")
    if not verify_refresh_token(payload.refresh_token, user["refresh_hash"]):
        raise HTTPException(status_code=401, detail="Refresh token mismatch (rotated)")
    # 회전: 새 refresh 발급 후 hash 교체
    new_refresh = create_refresh_token(sub)
    await db["users"].update_one({"_id": sub}, {"$set": {"refresh_hash": hash_refresh_token(new_refresh), "refresh_issued_at": datetime.now(timezone.utc)}})
    return TokenPair(access_token=create_access_token(sub), refresh_token=new_refresh)

@router.post("/password/change")
async def change_password(
    payload: PasswordChangeRequest,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await db["users"].find_one({"_id": user_id})
    if not user or not verify_password(payload.current_password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Current password is incorrect")

    await db["users"].update_one(
        {"_id": user_id},
        {"$set": {"password_hash": hash_password(payload.new_password)}}
    )
    return {"success": True}

@router.post("/password/reset/start")
async def password_reset_start(payload: PasswordResetStartRequest, db=Depends(get_db)):
    user = await db["users"].find_one({"email": payload.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    token = create_password_reset_token(user["_id"])  # raw token
    await db["users"].update_one({"_id": user["_id"]}, {"$set": {"password_reset_token": token, "password_reset_requested_at": datetime.now(timezone.utc)}})
    # TODO: send email via SMTP with link containing token
    return {"success": True, "message": "Password reset token issued", "token_debug": token}

@router.post("/password/reset/finish")
async def password_reset_finish(payload: PasswordResetFinishRequest, db=Depends(get_db)):
    decoded = decode_token(payload.token)
    if not decoded or decoded.get("type") != "reset":
        raise HTTPException(status_code=400, detail="Invalid reset token")
    sub = decoded.get("sub")
    user = await db["users"].find_one({"_id": sub})
    if not user or user.get("password_reset_token") != payload.token:
        raise HTTPException(status_code=400, detail="Reset token mismatch")
    await db["users"].update_one({"_id": sub}, {"$set": {"password_hash": hash_password(payload.new_password), "password_reset_token": None}})
    return {"success": True, "message": "Password updated"}

@router.post("/verify/email")
async def verify_email(payload: EmailVerifyRequest, db=Depends(get_db)):
    decoded = decode_token(payload.token)
    if not decoded or decoded.get("type") != "verify":
        raise HTTPException(status_code=400, detail="Invalid verification token")
    sub = decoded.get("sub")
    user = await db["users"].find_one({"_id": sub})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await db["users"].update_one({"_id": sub}, {"$set": {"email_verified": True}})
    return {"success": True, "message": "Email verified"}
