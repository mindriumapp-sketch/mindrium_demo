# backend/app/routers/auth.py

from datetime import datetime, timezone
from bson import ObjectId
import uuid
import os

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from pymongo.errors import DuplicateKeyError
import httpx

from core.config import get_settings
from db.mongo import get_db
from routers.custom_tags import ensure_default_custom_tags
from routers.worry_groups import ensure_default_worry_group
from schemas.auth import (
    TokenPair,
    SignupRequest,
    LoginRequest,
    RefreshRequest,
    PasswordResetStartRequest,
    PasswordResetFinishRequest,
    EmailVerifyRequest,
    PasswordChangeRequest,
)
from core.security import (
    sub_to_obj,
    get_user_obj_id,
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    create_password_reset_token,
    decode_token,
    hash_token,
    hash_refresh_token,
    verify_refresh_token,
)

settings = get_settings()
router = APIRouter(prefix="/auth")


# =========================================================
# phone 정규화 정책
# - MongoDB users.phone: digits(예: 01038472918) 로 저장
# - 플랫폼 claim 호출 시: 플랫폼 DB contact_information 이 하이픈 포함일 수 있으므로
#   010-3847-2918 형태로 포맷해서 전송
# =========================================================
def phone_to_digits(phone: str) -> str:
    raw = (phone or "").strip()
    return "".join(ch for ch in raw if ch.isdigit())


def digits_to_platform_format(digits: str) -> str:
    d = phone_to_digits(digits)
    # 010XXXXXXXX(11자리) -> 010-XXXX-XXXX
    if len(d) == 11 and d.startswith("010"):
        return f"{d[0:3]}-{d[3:7]}-{d[7:11]}"
    # 그 외: 일단 digits 그대로 (플랫폼 DB 저장 포맷이 다르면 여기서 정책 변경)
    return d

"""
# =========================================================
# 플랫폼 Claim API 호출
# - 성공: patient_id 반환
# - 실패: 플랫폼 detail을 가능한 그대로 전달
# 플랫폼에서 Claim API 삭제로 인한 주석처
# =========================================================
async def claim_patient_id_from_platform(mindrium_code: str, phone_digits: str) -> str:
    base_url = os.getenv("PLATFORM_BASE_URL", "http://localhost:8061").rstrip("/")
    url = f"{base_url}/api/onboarding/claim"

    code = (mindrium_code or "").strip()
    if not code:
        raise HTTPException(status_code=400, detail="mindrium_code(=code)가 비어있습니다.")
    if not code.isdigit() or len(code) != 6:
        raise HTTPException(status_code=400, detail="mindrium_code는 숫자 6자리여야 합니다.")

    phone_for_platform = digits_to_platform_format(phone_digits)
    if not phone_for_platform:
        raise HTTPException(status_code=400, detail="phone이 비어있습니다.")

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(
                url,
                json={"mindrium_code": code, "phone": phone_for_platform},
                headers={"Content-Type": "application/json"},
            )
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"플랫폼 Claim API 연결 실패: {e}")

    # 정상
    if resp.status_code == 200:
        data = resp.json()
        patient_id = data.get("patient_id")
        if not patient_id:
            raise HTTPException(status_code=502, detail="플랫폼 Claim API 응답에 patient_id가 없습니다.")
        return patient_id

    # 에러 detail 최대한 전달
    try:
        detail = resp.json().get("detail")
    except Exception:
        detail = resp.text

    # 플랫폼에서 이미 사용된 코드면 409 등을 줄 수도 있으니 그대로 매핑
    if resp.status_code in (400, 404, 409):
        raise HTTPException(status_code=resp.status_code, detail=detail or "플랫폼 Claim 실패")

    raise HTTPException(status_code=502, detail=f"플랫폼 Claim API 오류({resp.status_code}): {detail}")
"""

# =========================================================
# 플랫폼 Resolve API 호출
# =========================================================
async def resolve_patient_id_from_platform(mindrium_code: str) -> str:
    base_url = os.getenv("PLATFORM_BASE_URL", "http://platform_public_python:8061").rstrip("/")
    url = f"{base_url}/integrations/mindrium/resolve-patient-id"

    code = (mindrium_code or "").strip()
    if not code.isdigit() or len(code) != 6:
        raise HTTPException(status_code=400, detail="mindrium_code는 숫자 6자리여야 합니다.")

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(
                url,
                json={"code": code},
                headers={"Content-Type": "application/json"},
            )
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"플랫폼 Resolve API 연결 실패: {e}")

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"플랫폼 Resolve API 오류({resp.status_code})")

    data = resp.json()
    if not data.get("exists"):
        raise HTTPException(status_code=400, detail="유효하지 않은 mindrium code 입니다.")

    return data.get("patient_id")


@router.post("/signup", response_model=TokenPair)
async def signup(payload: SignupRequest, db=Depends(get_db)):
    # 1) 이메일 중복
    if await db["users"].find_one({"email": payload.email}):
        raise HTTPException(status_code=409, detail="Email already registered")

    # 2) 입력 검증
    phone_digits = phone_to_digits(payload.phone)
    if not phone_digits or len(phone_digits) < 9:
        raise HTTPException(status_code=400, detail="phone 형식이 올바르지 않습니다.")

    code = (payload.code or "").strip()
    if not code.isdigit() or len(code) != 6:
        raise HTTPException(status_code=400, detail="mindrium_code(code)는 숫자 6자리여야 합니다.")

    # 3) resolve (side-effect 없음)
    patient_id = await resolve_patient_id_from_platform(code)

    # 4) 이미 patient_id가 있으면 차단 (로직 레벨)
    if await db["users"].find_one({"patient_id": patient_id}):
        raise HTTPException(
            status_code=409,
            detail="이미 해당 코드(=patient_id)로 가입된 계정이 있습니다. 기존 계정으로 로그인 후 SNS 연동을 진행하세요."
        )

    # 5) insert (DB 유니크가 최종 방어)
    obj_id = ObjectId()
    user_id = f"user_{uuid.uuid4().hex[:8]}"
    now = datetime.now(timezone.utc)

    doc = {
        "_id": obj_id,
        "user_id": user_id,
        "email": payload.email,
        "name": payload.name,
        "gender": payload.gender,
        "code": code,
        "phone": phone_digits,
        "password_hash": hash_password(payload.password),
        "patient_id": patient_id,
        "survey_completed": False,
        "surveys": [],
        "email_verified": False,
        "created_at": now,
    }

    try:
        await db["users"].insert_one(doc)
    except DuplicateKeyError:
        # email 또는 patient_id unique 충돌
        raise HTTPException(status_code=409, detail="이미 가입된 사용자입니다.")

    # 기본 시딩/토큰
    await ensure_default_custom_tags(db, user_id)
    await ensure_default_worry_group(db, user_id)

    sub = str(obj_id)
    refresh_raw = create_refresh_token(sub)
    await db["users"].update_one(
        {"_id": obj_id},
        {"$set": {"refresh_hash": hash_refresh_token(refresh_raw), "refresh_issued_at": now}},
    )

    return TokenPair(
        access_token=create_access_token(sub),
        refresh_token=refresh_raw,
    )




# ===========================
# OAuth (MVP) - provider_sub 기반
# ===========================

class OAuthLoginRequest(BaseModel):
    provider_sub: str

class OAuthLinkRequest(BaseModel):
    provider_sub: str
    code: str


def normalize_provider(provider: str) -> str:
    p = (provider or "").strip().lower()
    if p not in ("kakao", "google", "naver"):
        raise HTTPException(status_code=400, detail="Unsupported provider")
    return p


@router.post("/oauth/{provider}/login")
async def oauth_login(provider: str, payload: OAuthLoginRequest, db=Depends(get_db)):
    provider = normalize_provider(provider)
    sub = (payload.provider_sub or "").strip()
    if not sub:
        raise HTTPException(status_code=400, detail="provider_sub is required")

    user = await db["users"].find_one({
        "identities": {"$elemMatch": {"provider": provider, "sub": sub}}
    })

    if not user:
        return {"needs_link": True}

    sub_claim = str(user["_id"])
    now = datetime.now(timezone.utc)
    refresh_raw = create_refresh_token(sub_claim)
    await db["users"].update_one(
        {"_id": user["_id"]},
        {"$set": {"refresh_hash": hash_refresh_token(refresh_raw), "refresh_issued_at": now}},
    )
    return TokenPair(access_token=create_access_token(sub_claim), refresh_token=refresh_raw)


@router.post("/oauth/{provider}/link", response_model=TokenPair)
async def oauth_link(provider: str, payload: OAuthLinkRequest, db=Depends(get_db)):
    provider = normalize_provider(provider)
    sub = (payload.provider_sub or "").strip()
    if not sub:
        raise HTTPException(status_code=400, detail="provider_sub is required")

    code = (payload.code or "").strip()
    if not code.isdigit() or len(code) != 6:
        raise HTTPException(status_code=400, detail="mindrium_code(code)는 숫자 6자리여야 합니다.")

    # 1) code -> patient_id (side-effect 없음)
    patient_id = await resolve_patient_id_from_platform(code)

    # 2) patient_id로 기존 계정 찾기
    user = await db["users"].find_one({"patient_id": patient_id})
    if not user:
        raise HTTPException(status_code=404, detail="해당 코드로 가입된 계정을 찾을 수 없습니다.")

    # 3) 동일 (provider, sub)가 이미 다른 계정에 붙어있으면 차단
    other = await db["users"].find_one({
        "identities": {"$elemMatch": {"provider": provider, "sub": sub}},
        "_id": {"$ne": user["_id"]},
    })
    if other:
        raise HTTPException(status_code=409, detail="이미 다른 계정에 연결된 소셜 계정입니다.")

    # 4) 이미 이 계정에 provider가 연결돼 있으면 그대로 로그인 처리(정책)
    identities = user.get("identities") or []
    for it in identities:
        if it.get("provider") == provider:
            sub_claim = str(user["_id"])
            now = datetime.now(timezone.utc)
            refresh_raw = create_refresh_token(sub_claim)
            await db["users"].update_one(
                {"_id": user["_id"]},
                {"$set": {"refresh_hash": hash_refresh_token(refresh_raw), "refresh_issued_at": now}},
            )
            return TokenPair(access_token=create_access_token(sub_claim), refresh_token=refresh_raw)

    # 5) identities에 추가
    now = datetime.now(timezone.utc)
    await db["users"].update_one(
        {"_id": user["_id"]},
        {"$push": {"identities": {"provider": provider, "sub": sub, "linked_at": now}}},
    )

    # 6) 토큰 발급
    sub_claim = str(user["_id"])
    refresh_raw = create_refresh_token(sub_claim)
    await db["users"].update_one(
        {"_id": user["_id"]},
        {"$set": {"refresh_hash": hash_refresh_token(refresh_raw), "refresh_issued_at": now}},
    )
    return TokenPair(access_token=create_access_token(sub_claim), refresh_token=refresh_raw)

@router.post("/login", response_model=TokenPair)
async def login(payload: LoginRequest, db=Depends(get_db)):
    user = await db["users"].find_one({"email": payload.email})
    if not user or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    sub = str(user["_id"])
    now = datetime.now(timezone.utc)
    refresh_raw = create_refresh_token(sub)

    await db["users"].update_one(
        {"_id": user["_id"]},
        {"$set": {"refresh_hash": hash_refresh_token(refresh_raw), "refresh_issued_at": now}},
    )
    return TokenPair(access_token=create_access_token(sub), refresh_token=refresh_raw)


@router.post("/refresh", response_model=TokenPair)
async def refresh(payload: RefreshRequest, db=Depends(get_db)):
    decoded = decode_token(payload.refresh_token, refresh=True)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    sub = decoded["sub"]
    obj_id = sub_to_obj(sub)

    user = await db["users"].find_one({"_id": obj_id})
    if not user or "refresh_hash" not in user:
        raise HTTPException(status_code=401, detail="Invalid refresh state")
    if not verify_refresh_token(payload.refresh_token, user["refresh_hash"]):
        raise HTTPException(status_code=401, detail="Refresh token mismatch (rotated)")

    now = datetime.now(timezone.utc)
    new_refresh = create_refresh_token(sub)
    await db["users"].update_one(
        {"_id": obj_id},
        {"$set": {"refresh_hash": hash_refresh_token(new_refresh), "refresh_issued_at": now}},
    )
    return TokenPair(access_token=create_access_token(sub), refresh_token=new_refresh)


@router.post("/password/change")
async def change_password(payload: PasswordChangeRequest, db=Depends(get_db), user_obj_id: ObjectId = Depends(get_user_obj_id)):
    user = await db["users"].find_one({"_id": user_obj_id})
    if not user or not verify_password(payload.current_password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Current password is incorrect")

    await db["users"].update_one(
        {"_id": user["_id"]},
        {
            "$set": {"password_hash": hash_password(payload.new_password)},
            "$unset": {"refresh_hash": "", "refresh_issued_at": ""},
        },
    )
    return {"success": True}


@router.post("/password/reset/start")
async def password_reset_start(payload: PasswordResetStartRequest, db=Depends(get_db)):
    user = await db["users"].find_one({"email": payload.email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    token = create_password_reset_token(str(user["_id"]))
    token_hash = hash_token(token)
    now = datetime.now(timezone.utc)

    await db["users"].update_one(
        {"_id": user["_id"]},
        {"$set": {"password_reset_hash": token_hash, "password_reset_requested_at": now}},
    )
    return {"success": True, "message": "Password reset token issued", "token_debug": token}


@router.post("/password/reset/finish")
async def password_reset_finish(payload: PasswordResetFinishRequest, db=Depends(get_db)):
    decoded = decode_token(payload.token)
    if not decoded or decoded.get("type") != "reset":
        raise HTTPException(status_code=400, detail="Invalid reset token")

    sub = decoded["sub"]
    obj_id = sub_to_obj(sub)

    user = await db["users"].find_one({"_id": obj_id})
    if not user:
        raise HTTPException(status_code=400, detail="Invalid reset token")

    stored_hash = user.get("password_reset_hash")
    incoming_hash = hash_token(payload.token)
    if not stored_hash or stored_hash != incoming_hash:
        raise HTTPException(status_code=400, detail="Reset token mismatch or already used")


    requested_at = user.get("password_reset_requested_at")
    if not requested_at:
        raise HTTPException(status_code=400, detail="Reset token state invalid")

    # Mongo에 naive datetime으로 들어온 경우(타임존 정보 없음) -> UTC로 간주
    if isinstance(requested_at, datetime) and requested_at.tzinfo is None:
        requested_at = requested_at.replace(tzinfo=timezone.utc)

    now = datetime.now(timezone.utc)
    elapsed_sec = (now - requested_at).total_seconds()


    if elapsed_sec > settings.reset_token_expire_minutes * 60:
        raise HTTPException(status_code=400, detail="Reset token has expired")

    await db["users"].update_one(
        {"_id": obj_id},
        {"$set": {"password_hash": hash_password(payload.new_password)}, "$unset": {"password_reset_hash": "", "password_reset_requested_at": ""}},
    )
    return {"success": True, "message": "Password updated"}


@router.post("/verify/email")
async def verify_email(payload: EmailVerifyRequest, db=Depends(get_db)):
    decoded = decode_token(payload.token)
    if not decoded or decoded.get("type") != "verify":
        raise HTTPException(status_code=400, detail="Invalid verification token")

    sub = decoded["sub"]
    obj_id = sub_to_obj(sub)

    user = await db["users"].find_one({"_id": obj_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    await db["users"].update_one({"_id": obj_id}, {"$set": {"email_verified": True}})
    return {"success": True, "message": "Email verified"}
