from datetime import datetime, timezone
from typing import List, Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, Header, status

from db.mongo import get_db
from core.security import decode_token
from schemas.diary import DiaryCreate, DiaryResponse, DiaryUpdate

router = APIRouter(prefix="/diaries", tags=["diaries"])

USERS_COLLECTION = "users"


async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")


def _serialize_diary(doc: dict) -> dict:
    def _ensure_tz(dt: datetime) -> datetime:
        if dt.tzinfo is None:
            return dt.replace(tzinfo=timezone.utc)
        return dt

    def _parse_datetime(value, fallback=None):
        if isinstance(value, datetime):
            return _ensure_tz(value)
        if isinstance(value, str):
            try:
                return _ensure_tz(datetime.fromisoformat(value))
            except Exception:
                pass
        if fallback is not None:
            return fallback
        return datetime.now(timezone.utc)

    def _parse_group(value):
        if isinstance(value, int):
            return value
        if isinstance(value, float):
            return int(value)
        if value is None:
            return 0
        try:
            return int(value)
        except Exception:
            return 0

    return {
        "diaryId": doc.get("diary_id") or doc.get("_id") or f"diary_{uuid.uuid4().hex[:8]}",
        "group_Id": _parse_group(doc.get("group_Id")),
        "activating_events": doc.get("activating_events", ""),
        "belief": doc.get("belief", []),
        "consequence_p": doc.get("consequence_p", []),
        "consequence_e": doc.get("consequence_e", []),
        "consequence_b": doc.get("consequence_b", []),
        "sudScores": doc.get("sudScores", []),
        "alternativeThoughts": doc.get("alternativeThoughts", []),
        "alarms": doc.get("alarms", []),
        "latitude": doc.get("latitude"),
        "longitude": doc.get("longitude"),
        "addressName": doc.get("addressName"),
        "createdAt": _parse_datetime(doc.get("createdAt")),
        "updatedAt": _parse_datetime(doc.get("updatedAt"), fallback=_parse_datetime(doc.get("createdAt"))),
    }


async def _get_user_or_404(db, user_id: str) -> dict:
    user = await db[USERS_COLLECTION].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def _find_diary_in_user(user: dict, diary_id: str) -> Optional[dict]:
    for diary in user.get("diaries", []):
        if diary.get("diary_id") == diary_id:
            return diary
    return None


@router.post("", response_model=DiaryResponse, status_code=status.HTTP_201_CREATED)
async def create_diary(
    payload: DiaryCreate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    now = datetime.now(timezone.utc)
    diary_id = f"diary_{uuid.uuid4().hex[:8]}"

    diary_doc = {
        "diary_id": diary_id,
        "group_Id": payload.group_id,
        "activating_events": payload.activating_events,
        "belief": payload.belief,
        "consequence_p": payload.consequence_p,
        "consequence_e": payload.consequence_e,
        "consequence_b": payload.consequence_b,
        "sudScores": payload.sud_scores,
        "alternativeThoughts": payload.alternative_thoughts,
        "alarms": payload.alarms,
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "addressName": payload.address_name,
        "createdAt": now,
        "updatedAt": now,
    }

    user = await db[USERS_COLLECTION].find_one({"_id": user_id}, {"diaries": 1})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    diaries = list(user.get("diaries", []))
    diaries.append(diary_doc)

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    return DiaryResponse(**_serialize_diary(diary_doc))


@router.get("", response_model=List[DiaryResponse])
async def list_diaries(
    group_id: Optional[int] = None,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await _get_user_or_404(db, user_id)
    diaries = user.get("diaries", [])

    filtered = []
    for diary in diaries:
        if group_id is not None and diary.get("group_Id") != group_id:
            continue
        filtered.append(DiaryResponse(**_serialize_diary(diary)))

    filtered.sort(
        key=lambda d: (d.created_at or datetime.min.replace(tzinfo=timezone.utc)),
        reverse=True,
    )
    return filtered


@router.get("/{diary_id}", response_model=DiaryResponse)
async def get_diary(
    diary_id: str,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await _get_user_or_404(db, user_id)
    diary = _find_diary_in_user(user, diary_id)
    if not diary:
        raise HTTPException(status_code=404, detail="Diary not found")
    return DiaryResponse(**_serialize_diary(diary))


@router.put("/{diary_id}", response_model=DiaryResponse)
async def update_diary(
    diary_id: str,
    payload: DiaryUpdate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    update_data = payload.dict(exclude_unset=True, by_alias=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    update_data["updatedAt"] = datetime.now(timezone.utc)

    user = await _get_user_or_404(db, user_id)
    diaries = list(user.get("diaries", []))
    updated = False
    updated_diary = None
    for idx, diary in enumerate(diaries):
        if diary.get("diary_id") == diary_id:
            diaries[idx] = {**diary, **update_data}
            updated_diary = diaries[idx]
            updated = True
            break

    if not updated:
        raise HTTPException(status_code=404, detail="Diary not found")

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    if not updated_diary:
        raise HTTPException(status_code=500, detail="Diary update failed")

    return DiaryResponse(**_serialize_diary(updated_diary))
