from datetime import datetime, timezone
from typing import List, Optional, Dict
import uuid

from fastapi import APIRouter, Depends, HTTPException, Header, status

from db.mongo import get_db
from core.security import decode_token
from schemas.diary import (
    DiaryCreate,
    DiaryResponse,
    DiaryUpdate,
    AlarmCreate,
    AlarmResponse,
    AlarmUpdate,
)

router = APIRouter(prefix="/diaries", tags=["diaries"])

USERS_COLLECTION = "users"


def _ensure_tz(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def _parse_datetime_value(value, fallback=None):
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


async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")


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


def _serialize_alarm(doc: dict) -> dict:
    return {
        "alarmId": doc.get("alarm_id") or f"alarm_{uuid.uuid4().hex[:6]}",
        "time": doc.get("time", ""),
        "location_desc": doc.get("location_desc"),
        "repeat_option": doc.get("repeat_option"),
        "weekDays": doc.get("weekDays", []),
        "reminder_minutes": doc.get("reminder_minutes"),
        "enter": doc.get("enter", False),
        "exit": doc.get("exit", False),
        "createdAt": _parse_datetime_value(doc.get("createdAt")),
        "updatedAt": _parse_datetime_value(
            doc.get("updatedAt"), fallback=_parse_datetime_value(doc.get("createdAt"))
        ),
    }


def _normalize_alarms(raw) -> List[dict]:
    normalized: List[dict] = []
    if isinstance(raw, dict):
        iterable = raw.items()
        for key, value in iterable:
            if not isinstance(value, dict):
                continue
            doc = dict(value or {})
            alarm_id = doc.get("alarm_id") or doc.get("alarmId") or key or f"alarm_{uuid.uuid4().hex[:6]}"
            doc["alarm_id"] = alarm_id
            created = doc.get("createdAt") or doc.get("created_at")
            doc["createdAt"] = _parse_datetime_value(created)
            doc["updatedAt"] = _parse_datetime_value(doc.get("updatedAt") or doc.get("createdAt"))
            normalized.append(doc)
    elif isinstance(raw, list):
        for value in raw:
            if not isinstance(value, dict):
                continue
            doc = dict(value or {})
            alarm_id = doc.get("alarm_id") or doc.get("alarmId") or f"alarm_{uuid.uuid4().hex[:6]}"
            doc["alarm_id"] = alarm_id
            created = doc.get("createdAt") or doc.get("created_at")
            doc["createdAt"] = _parse_datetime_value(created)
            doc["updatedAt"] = _parse_datetime_value(doc.get("updatedAt") or doc.get("createdAt"))
            normalized.append(doc)
    normalized.sort(key=lambda d: d["createdAt"])
    return normalized


def _parse_sud_value(value):
    if isinstance(value, (int, float)):
        return max(0, min(10, int(value)))
    if isinstance(value, str):
        try:
            return max(0, min(10, int(float(value))))
        except Exception:
            return 0
    return 0


def _normalize_sud_scores(raw) -> List[dict]:
    if not isinstance(raw, list):
        return []

    normalized: List[dict] = []
    for item in raw:
        if isinstance(item, dict):
            before = _parse_sud_value(item.get("before_sud") or item.get("beforeSud"))
            after = item.get("after_sud") or item.get("afterSud")
            after = None if after is None else _parse_sud_value(after)
            created_at = _parse_datetime_value(item.get("created_at") or item.get("createdAt"))
            updated_at = _parse_datetime_value(
                item.get("updated_at") or item.get("updatedAt"), fallback=created_at
            )
        else:
            before = _parse_sud_value(item)
            after = before
            created_at = datetime.now(timezone.utc)
            updated_at = created_at

        entry = {
            "sud_id": (item.get("sud_id") if isinstance(item, dict) else None)
            or f"sud_{uuid.uuid4().hex[:8]}",
            "before_sud": before,
            "after_sud": after,
            "created_at": created_at,
            "updated_at": updated_at,
        }
        normalized.append(entry)

    normalized.sort(key=lambda e: e["created_at"])
    return normalized


def _serialize_sud_entry(doc: dict) -> dict:
    return {
        "sud_id": doc.get("sud_id"),
        "before_sud": doc.get("before_sud"),
        "after_sud": doc.get("after_sud"),
        "created_at": _parse_datetime_value(doc.get("created_at")),
        "updated_at": _parse_datetime_value(doc.get("updated_at") or doc.get("created_at")),
    }


def _serialize_diary(doc: dict, *, array_index: int | None = None) -> dict:
    alarms_raw = _normalize_alarms(doc.get("alarms", []))
    doc["alarms"] = alarms_raw
    sud_entries = _normalize_sud_scores(doc.get("sudScores", []))
    doc["sudScores"] = sud_entries

    return {
        "diaryId": doc.get("diary_id") or doc.get("_id") or f"diary_{uuid.uuid4().hex[:8]}",
        "group_Id": _parse_group(doc.get("group_Id")),
        "activating_events": doc.get("activating_events", ""),
        "belief": doc.get("belief", []),
        "consequence_p": doc.get("consequence_p", []),
        "consequence_e": doc.get("consequence_e", []),
        "consequence_b": doc.get("consequence_b", []),
        "sudScores": [_serialize_sud_entry(entry) for entry in sud_entries],
        "alternativeThoughts": doc.get("alternativeThoughts", []),
        "alarms": [AlarmResponse(**_serialize_alarm(alarm_doc)) for alarm_doc in alarms_raw],
        "latitude": doc.get("latitude"),
        "longitude": doc.get("longitude"),
        "addressName": doc.get("addressName"),
        "createdAt": _parse_datetime_value(doc.get("createdAt")),
        "updatedAt": _parse_datetime_value(
            doc.get("updatedAt"), fallback=_parse_datetime_value(doc.get("createdAt"))
        ),
        "arrayIndex": array_index,
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


def _find_diary_index(diaries: List[dict], diary_id: str) -> int:
    for idx, diary in enumerate(diaries):
        if diary.get("diary_id") == diary_id:
            return idx
    return -1


def _find_alarm_index(alarms: List[dict], alarm_id: str) -> int:
    for idx, alarm in enumerate(alarms):
        if alarm.get("alarm_id") == alarm_id:
            return idx
    return -1


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
        "sudScores": _normalize_sud_scores(payload.sud_scores),
        "alternativeThoughts": payload.alternative_thoughts,
        "alarms": _normalize_alarms(payload.alarms),
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
    for idx, diary in enumerate(diaries):
        if group_id is not None and diary.get("group_Id") != group_id:
            continue
        filtered.append(DiaryResponse(**_serialize_diary(diary, array_index=idx)))

    filtered.sort(key=lambda d: d.created_at or datetime.now(timezone.utc), reverse=True)
    return filtered


@router.get("/latest", response_model=DiaryResponse)
async def get_latest_diary(
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    """
    사용자의 일기 배열에서 '마지막 요소'를 최신으로 간주하여 반환합니다.
    정렬/타임스탬프와 무관하게 항상 배열 끝의 요소를 돌려줍니다.
    """
    user = await _get_user_or_404(db, user_id)
    diaries = user.get("diaries", [])
    if not diaries:
        raise HTTPException(status_code=404, detail="No diaries")
    latest = diaries[-1]
    return DiaryResponse(**_serialize_diary(latest, array_index=len(diaries) - 1))


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

    now = datetime.now(timezone.utc)
    update_data["updatedAt"] = now
    if "alarms" in update_data:
        update_data["alarms"] = _normalize_alarms(update_data["alarms"])
    if "sudScores" in update_data:
        update_data["sudScores"] = _normalize_sud_scores(update_data["sudScores"])

    user = await _get_user_or_404(db, user_id)
    diaries = list(user.get("diaries", []))
    updated = False
    updated_diary = None
    for idx, diary in enumerate(diaries):
        if diary.get("diary_id") == diary_id:
            # realOddness는 belief 기준 병합
            if "realOddness" in update_data:
                incoming = update_data.pop("realOddness") or []
                existing = list(diary.get("realOddness", []))
                by_belief: Dict[str, dict] = {}
                for e in existing:
                    if isinstance(e, dict) and e.get("belief"):
                        by_belief[str(e.get("belief")).strip()] = dict(e)
                for e in incoming:
                    if isinstance(e, dict) and e.get("belief"):
                        key = str(e.get("belief")).strip()
                        prev = by_belief.get(key, {"belief": key})
                        # before/after 각각 개별 필드만 갱신
                        if "before" in e and e.get("before") is not None:
                            prev["before"] = int(e.get("before"))
                        if "after" in e and e.get("after") is not None:
                            prev["after"] = int(e.get("after"))
                        by_belief[key] = prev
                merged_real = list(by_belief.values())
                diary["realOddness"] = merged_real
                diary["updatedAt"] = now
                # 나머지 필드(있다면) 평범 병합
                diaries[idx] = {**diary, **update_data}
            else:
                diaries[idx] = {**diary, **update_data}
            updated_diary = diaries[idx]
            updated = True
            break

    if not updated or updated_diary is None:
        raise HTTPException(status_code=404, detail="Diary not found")

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    return DiaryResponse(**_serialize_diary(updated_diary))


@router.get("/{diary_id}/alarms", response_model=List[AlarmResponse])
async def list_alarms(
    diary_id: str,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await _get_user_or_404(db, user_id)
    diary = _find_diary_in_user(user, diary_id)
    if not diary:
        raise HTTPException(status_code=404, detail="Diary not found")
    alarms = _normalize_alarms(diary.get("alarms", []))
    return [AlarmResponse(**_serialize_alarm(a)) for a in alarms]


@router.post("/{diary_id}/alarms", response_model=AlarmResponse, status_code=status.HTTP_201_CREATED)
async def create_alarm(
    diary_id: str,
    payload: AlarmCreate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await _get_user_or_404(db, user_id)
    diaries = list(user.get("diaries", []))
    diary_idx = _find_diary_index(diaries, diary_id)
    if diary_idx == -1:
        raise HTTPException(status_code=404, detail="Diary not found")

    now = datetime.now(timezone.utc)
    alarm_id = f"alarm_{uuid.uuid4().hex[:6]}"
    alarm_doc = {
        "alarm_id": alarm_id,
        "time": payload.time,
        "location_desc": payload.location_desc,
        "repeat_option": payload.repeat_option,
        "weekDays": payload.weekdays,
        "reminder_minutes": payload.reminder_minutes,
        "enter": payload.enter,
        "exit": payload.exit,
        "createdAt": now,
        "updatedAt": now,
    }

    alarms = _normalize_alarms(diaries[diary_idx].get("alarms", []))
    alarms.append(alarm_doc)
    diaries[diary_idx]["alarms"] = alarms

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    return AlarmResponse(**_serialize_alarm(alarm_doc))


@router.put("/{diary_id}/alarms/{alarm_id}", response_model=AlarmResponse)
async def update_alarm(
    diary_id: str,
    alarm_id: str,
    payload: AlarmUpdate,
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

    alarms = _normalize_alarms(diaries[diary_idx].get("alarms", []))
    alarm_idx = _find_alarm_index(alarms, alarm_id)
    if alarm_idx == -1:
        raise HTTPException(status_code=404, detail="Alarm not found")

    alarms[alarm_idx] = {
        **alarms[alarm_idx],
        **update_data,
        "updatedAt": datetime.now(timezone.utc),
    }
    diaries[diary_idx]["alarms"] = alarms

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    return AlarmResponse(**_serialize_alarm(alarms[alarm_idx]))


@router.delete("/{diary_id}/alarms/{alarm_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_alarm(
    diary_id: str,
    alarm_id: str,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    user = await _get_user_or_404(db, user_id)
    diaries = list(user.get("diaries", []))
    diary_idx = _find_diary_index(diaries, diary_id)
    if diary_idx == -1:
        raise HTTPException(status_code=404, detail="Diary not found")

    alarms = _normalize_alarms(diaries[diary_idx].get("alarms", []))
    alarm_idx = _find_alarm_index(alarms, alarm_id)
    if alarm_idx == -1:
        raise HTTPException(status_code=404, detail="Alarm not found")

    alarms.pop(alarm_idx)
    diaries[diary_idx]["alarms"] = alarms

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"diaries": diaries}},
    )

    return None
