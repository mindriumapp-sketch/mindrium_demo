from datetime import datetime, timezone
from typing import List
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, status

from core.security import decode_token
from db.mongo import get_db
from schemas.sud import SudScoreCreate, SudScoreResponse, SudScoreUpdate

router = APIRouter(prefix="/sud-scores", tags=["sud_scores"])

USERS_COLLECTION = "users"


def _ensure_tz(dt: datetime | None) -> datetime:
    if dt is None:
        return datetime.now(timezone.utc)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")


async def _get_user_or_404(db, user_id: str) -> dict:
    user = await db[USERS_COLLECTION].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def _find_diary_index(diaries: List[dict], diary_id: str) -> int:
    for idx, diary in enumerate(diaries):
        if diary.get("diary_id") == diary_id:
            return idx
    return -1


def _find_sud_index(entries: List[dict], sud_id: str) -> int:
    for idx, entry in enumerate(entries):
        if entry.get("sud_id") == sud_id:
            return idx
    return -1


def _serialize_entry(doc: dict) -> dict:
    return {
        "sud_id": doc.get("sud_id"),
        "diary_id": doc.get("diary_id"),
        "before_sud": doc.get("before_sud"),
        "after_sud": doc.get("after_sud"),
        "created_at": _ensure_tz(doc.get("created_at")),
        "updated_at": _ensure_tz(doc.get("updated_at") or doc.get("created_at")),
    }


@router.post("", response_model=SudScoreResponse, status_code=status.HTTP_201_CREATED)
async def create_sud_score(
    payload: SudScoreCreate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await _get_user_or_404(db, user_id)
    diaries = list(user.get("diaries", []))
    diary_idx = _find_diary_index(diaries, payload.diary_id)
    if diary_idx == -1:
        raise HTTPException(status_code=404, detail="Diary not found")

    now = datetime.now(timezone.utc)
    entries = list(diaries[diary_idx].get("sudScores", []))

    # 정책: 새로 추가하지 않고 "가장 최근 항목"을 갱신
    if entries:
        target_idx = len(entries) - 1
        updated_entry = {
            **entries[target_idx],
            "before_sud": payload.before_sud if payload.before_sud is not None else entries[target_idx].get("before_sud"),
            "after_sud": payload.after_sud if payload.after_sud is not None else entries[target_idx].get("after_sud"),
            "updated_at": now,
        }
        # sud_id/diary_id/created_at 보존
        updated_entry["sud_id"] = entries[target_idx].get("sud_id") or f"sud_{uuid.uuid4().hex[:8]}"
        updated_entry["diary_id"] = payload.diary_id
        updated_entry["created_at"] = entries[target_idx].get("created_at") or now
        entries[target_idx] = updated_entry
        entry = updated_entry
    else:
        sud_id = f"sud_{uuid.uuid4().hex[:8]}"
        entry = {
            "sud_id": sud_id,
            "diary_id": payload.diary_id,
            "before_sud": payload.before_sud,
            "after_sud": payload.after_sud,
            "created_at": now,
            "updated_at": now,
        }
        entries.append(entry)

    diaries[diary_idx]["sudScores"] = entries
    diaries[diary_idx]["updatedAt"] = now

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    return SudScoreResponse(**_serialize_entry(entry))


@router.get("/{diary_id}", response_model=List[SudScoreResponse])
async def list_sud_scores(
    diary_id: str,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await _get_user_or_404(db, user_id)
    diary = next((d for d in user.get("diaries", []) if d.get("diary_id") == diary_id), None)
    if not diary:
        raise HTTPException(status_code=404, detail="Diary not found")

    entries = list(diary.get("sudScores", []))
    entries.sort(key=lambda e: _ensure_tz(e.get("created_at")), reverse=True)
    return [SudScoreResponse(**_serialize_entry(entry)) for entry in entries]


@router.put("/{diary_id}/{sud_id}", response_model=SudScoreResponse)
async def update_sud_score(
    diary_id: str,
    sud_id: str,
    payload: SudScoreUpdate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    update_data = payload.dict(exclude_unset=True, by_alias=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    user = await _get_user_or_404(db, user_id)
    diaries = list(user.get("diaries", []))
    diary_idx = _find_diary_index(diaries, diary_id)
    if diary_idx == -1:
        raise HTTPException(status_code=404, detail="Diary not found")

    entries = list(diaries[diary_idx].get("sudScores", []))
    sud_idx = _find_sud_index(entries, sud_id)
    if sud_idx == -1:
        raise HTTPException(status_code=404, detail="SUD record not found")

    now = datetime.now(timezone.utc)
    entries[sud_idx] = {
        **entries[sud_idx],
        **update_data,
        "updated_at": now,
    }
    diaries[diary_idx]["sudScores"] = entries
    diaries[diary_idx]["updatedAt"] = now

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    return SudScoreResponse(**_serialize_entry(entries[sud_idx]))
