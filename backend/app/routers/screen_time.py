from datetime import datetime, timezone, timedelta
try:
    from zoneinfo import ZoneInfo
except ModuleNotFoundError:  # pragma: no cover
    ZoneInfo = None
from typing import Tuple

from fastapi import APIRouter, Depends, Header, HTTPException, Query

from core.security import decode_token
from db.mongo import get_db
from schemas.screen_time import ScreenTimeCreate, ScreenTimeEntry, ScreenTimeSummary

router = APIRouter(prefix="/users/me/screen-time", tags=["screen-time"])

COLLECTION = "screen_time"

def _get_kst_tz():
    if ZoneInfo is not None:
        try:
            return ZoneInfo("Asia/Seoul")
        except Exception:
            pass
    return timezone(timedelta(hours=9))


KST = _get_kst_tz()


async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _coerce_datetime(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _serialize_entry(doc: dict) -> dict:
    return {
        "id": str(doc.get("_id")),
        "start_time": _coerce_datetime(doc.get("start_time")),
        "end_time": _coerce_datetime(doc.get("end_time")),
        "duration_minutes": float(doc.get("duration_minutes", 0)),
        "created_at": _coerce_datetime(doc.get("created_at")),
        "platform": doc.get("platform"),
    }


def _kst_midnight(now_utc: datetime) -> datetime:
    now_kst = now_utc.astimezone(KST)
    return datetime(now_kst.year, now_kst.month, now_kst.day, tzinfo=KST)


async def _window_minutes(collection, user_id: str, start_utc: datetime, end_utc: datetime) -> Tuple[float, int]:
    total = 0.0
    sessions = 0
    cursor = collection.find(
        {
            "user_id": user_id,
            "end_time": {"$gt": start_utc},
            "start_time": {"$lt": end_utc},
        }
    )
    async for doc in cursor:
        st = _coerce_datetime(doc.get("start_time"))
        et = _coerce_datetime(doc.get("end_time"))
        if not isinstance(st, datetime) or not isinstance(et, datetime):
            continue
        overlap_start = max(st, start_utc)
        overlap_end = min(et, end_utc)
        if overlap_end <= overlap_start:
            continue
        total += (overlap_end - overlap_start).total_seconds() / 60
        sessions += 1
    return total, sessions


@router.post("", response_model=ScreenTimeEntry)
async def create_screen_time_entry(
    payload: ScreenTimeCreate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    start = _ensure_utc(payload.start_time)
    end = _ensure_utc(payload.end_time)
    if end <= start:
        raise HTTPException(status_code=400, detail="end_time must be after start_time")

    duration = (end - start).total_seconds() / 60
    if duration <= 0:
        raise HTTPException(status_code=400, detail="duration must be positive")

    doc = {
        "user_id": user_id,
        "start_time": start,
        "end_time": end,
        "duration_minutes": round(duration, 2),
        "platform": payload.platform,
        "created_at": datetime.now(timezone.utc),
    }
    result = await db[COLLECTION].insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize_entry(doc)


@router.get("", response_model=list[ScreenTimeEntry])
async def list_screen_time_entries(
    limit: int = Query(20, ge=1, le=200),
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    cursor = (
        db[COLLECTION]
        .find({"user_id": user_id})
        .sort("end_time", -1)
        .limit(limit)
    )
    entries = []
    async for doc in cursor:
        entries.append(_serialize_entry(doc))
    return entries


@router.get("/summary", response_model=ScreenTimeSummary)
async def get_screen_time_summary(
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    collection = db[COLLECTION]
    now_utc = datetime.now(timezone.utc)
    today_start_kst = _kst_midnight(now_utc)
    today_end_kst = today_start_kst + timedelta(days=1)
    week_start_kst = today_start_kst - timedelta(days=6)

    today_start_utc = today_start_kst.astimezone(timezone.utc)
    today_end_utc = today_end_kst.astimezone(timezone.utc)
    week_start_utc = week_start_kst.astimezone(timezone.utc)

    today_minutes, _ = await _window_minutes(collection, user_id, today_start_utc, today_end_utc)
    week_minutes, week_sessions = await _window_minutes(collection, user_id, week_start_utc, today_end_utc)

    total_pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {"_id": None, "sum": {"$sum": "$duration_minutes"}}},
    ]
    total_docs = await collection.aggregate(total_pipeline).to_list(length=1)
    total_minutes = float(total_docs[0]["sum"]) if total_docs else 0.0

    last_entry = await collection.find_one({"user_id": user_id}, sort=[("end_time", -1)])
    last_entry_at = _coerce_datetime(last_entry.get("end_time")) if last_entry else None

    return ScreenTimeSummary(
        totalMinutes=round(total_minutes, 2),
        todayMinutes=round(today_minutes, 2),
        weekMinutes=round(week_minutes, 2),
        sessions=week_sessions,
        lastEntryAt=last_entry_at,
    )
