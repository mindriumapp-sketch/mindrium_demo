from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, status

from core.security import decode_token
from db.mongo import get_db
from schemas.notification import (
    NotificationCreate,
    NotificationDescriptionUpdate,
    NotificationTimeUpdate,
    NotificationUpdate,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])

COLLECTION = "notification_settings"


async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")


def _object_id(value: str) -> ObjectId:
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(status_code=404, detail="Notification not found")


def _clean_text(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    text = value.strip()
    return text or None


def _normalize_repeat_option(value: Optional[str]) -> str:
    if not value:
        return "none"
    lower = value.lower()
    if lower not in {"none", "daily", "weekly"}:
        return "none"
    return lower


def _normalize_time(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    parts = value.split(":")
    if len(parts) < 2:
        return None
    try:
        hour = int(parts[0])
        minute = int(parts[1])
    except ValueError:
        return None
    if hour < 0 or hour > 23 or minute < 0 or minute > 59:
        return None
    return f"{hour:02d}:{minute:02d}"


def _normalize_weekdays(values: Optional[List[int]]) -> List[int]:
    if not values:
        return []
    normalized = sorted({int(v) for v in values if isinstance(v, (int, float)) or str(v).isdigit()})
    return [v for v in normalized if v > 0]


def _time_key(time_value: Optional[str], repeat_option: str, weekdays: List[int]) -> Optional[str]:
    if not time_value:
        return None
    repeat_for_key = repeat_option
    if repeat_for_key == "none":
        repeat_for_key = "daily"
    normalized_weekdays: List[int] = []
    if repeat_for_key == "weekly" and weekdays:
        normalized_weekdays = sorted(set(weekdays))
    wd_csv = ",".join(str(v) for v in normalized_weekdays)
    return f"t={time_value}|rep={repeat_for_key}|wd={wd_csv}"


def _duplicate_filter(doc: dict) -> Optional[dict]:
    time_value = doc.get("time")
    has_time = bool(time_value)
    has_coords = doc.get("latitude") is not None and doc.get("longitude") is not None
    has_addr = bool(doc.get("location"))
    if has_time and not has_coords and not has_addr:
        time_key_value = doc.get("time_key")
        if time_key_value:
            return {
                "user_id": doc["user_id"],
                "abc_id": doc["abc_id"],
                "time_key": time_key_value,
            }
    if has_coords:
        return {
            "user_id": doc["user_id"],
            "abc_id": doc["abc_id"],
            "latitude": doc.get("latitude"),
            "longitude": doc.get("longitude"),
            "notify_enter": doc.get("notify_enter", False),
            "notify_exit": doc.get("notify_exit", False),
        }
    return None


def _build_doc_from_payload(
    payload: NotificationCreate,
    *,
    abc_id: str,
    user_id: str,
) -> dict:
    normalized_time = _normalize_time(payload.time)
    repeat_option = _normalize_repeat_option(payload.repeat_option)
    weekdays = _normalize_weekdays(payload.weekdays)
    doc = {
        "user_id": user_id,
        "abc_id": abc_id,
        "time": normalized_time,
        "repeat_option": repeat_option,
        "weekdays": weekdays,
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "location": _clean_text(payload.location),
        "description": _clean_text(payload.description),
        "cause": _clean_text(payload.cause),
        "reminder_minutes": payload.reminder_minutes,
        "notify_enter": bool(payload.notify_enter),
        "notify_exit": bool(payload.notify_exit),
    }
    time_key_value = _time_key(normalized_time, repeat_option, weekdays)
    if time_key_value:
        doc["time_key"] = time_key_value
    return {k: v for k, v in doc.items() if v is not None}


def _serialize_notification(doc: dict) -> dict:
    if not doc:
        return {}
    saved_at = doc.get("saved_at")
    updated_at = doc.get("updated_at")
    return {
        "_id": str(doc.get("_id")),
        "id": str(doc.get("_id")),
        "settingId": str(doc.get("_id")),
        "abc_id": doc.get("abc_id"),
        "time": doc.get("time"),
        "repeat_option": doc.get("repeat_option"),
        "weekdays": doc.get("weekdays", []),
        "latitude": doc.get("latitude"),
        "longitude": doc.get("longitude"),
        "location": doc.get("location"),
        "description": doc.get("description"),
        "cause": doc.get("cause"),
        "reminder_minutes": doc.get("reminder_minutes"),
        "notify_enter": doc.get("notify_enter", False),
        "notify_exit": doc.get("notify_exit", False),
        "time_key": doc.get("time_key"),
        "saved_at": saved_at.isoformat() if saved_at else None,
        "updated_at": updated_at.isoformat() if updated_at else None,
    }


async def _get_notification_or_404(db, user_id: str, abc_id: str, setting_id: str) -> dict:
    oid = _object_id(setting_id)
    doc = await db[COLLECTION].find_one({"_id": oid, "user_id": user_id, "abc_id": abc_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Notification not found")
    return doc


@router.get("")
async def list_notifications(
    abc_id: Optional[str] = Query(None, alias="abc_id"),
    location_only: bool = Query(False, alias="location_only"),
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    query = {"user_id": user_id}
    if abc_id:
        query["abc_id"] = abc_id
    if location_only:
        query["latitude"] = {"$ne": None}
        query["longitude"] = {"$ne": None}
    cursor = db[COLLECTION].find(query).sort("saved_at", -1)
    docs = await cursor.to_list(length=200)
    return [_serialize_notification(doc) for doc in docs]


@router.get("/latest")
async def latest_notification(
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    doc = await db[COLLECTION].find_one(
        {"user_id": user_id},
        sort=[("saved_at", -1), ("updated_at", -1)],
    )
    if not doc:
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    return _serialize_notification(doc)


@router.post("/{abc_id}")
async def create_notification(
    abc_id: str,
    payload: NotificationCreate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    base_doc = _build_doc_from_payload(payload, abc_id=abc_id, user_id=user_id)
    now = datetime.now(timezone.utc)
    base_doc["saved_at"] = now
    base_doc["updated_at"] = now
    duplicate_query = _duplicate_filter(base_doc) if base_doc else None
    if duplicate_query:
        existing = await db[COLLECTION].find_one(duplicate_query)
        if existing:
            base_doc["saved_at"] = existing.get("saved_at", now)
            await db[COLLECTION].update_one({"_id": existing["_id"]}, {"$set": base_doc})
            merged = {**existing, **base_doc}
            return _serialize_notification(merged)

    result = await db[COLLECTION].insert_one(base_doc)
    base_doc["_id"] = result.inserted_id
    return _serialize_notification(base_doc)


@router.put("/{abc_id}/{setting_id}")
async def update_notification(
    abc_id: str,
    setting_id: str,
    payload: NotificationUpdate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    doc = await _get_notification_or_404(db, user_id, abc_id, setting_id)
    fields_set = payload.__fields_set__
    updates: dict = {}
    unsets: dict = {}

    if "time" in fields_set:
        updates["time"] = _normalize_time(payload.time)
        if updates["time"] is None:
            unsets["time"] = ""
            updates.pop("time")
    if "repeat_option" in fields_set:
        updates["repeat_option"] = _normalize_repeat_option(payload.repeat_option)
    if "weekdays" in fields_set:
        updates["weekdays"] = _normalize_weekdays(payload.weekdays)
    if "latitude" in fields_set:
        if payload.latitude is None:
            unsets["latitude"] = ""
        else:
            updates["latitude"] = payload.latitude
    if "longitude" in fields_set:
        if payload.longitude is None:
            unsets["longitude"] = ""
        else:
            updates["longitude"] = payload.longitude
    if "location" in fields_set:
        cleaned = _clean_text(payload.location)
        if cleaned is None:
            unsets["location"] = ""
        else:
            updates["location"] = cleaned
    if "description" in fields_set:
        cleaned = _clean_text(payload.description)
        if cleaned is None:
            unsets["description"] = ""
        else:
            updates["description"] = cleaned
    if "cause" in fields_set:
        cleaned = _clean_text(payload.cause)
        if cleaned is None:
            unsets["cause"] = ""
        else:
            updates["cause"] = cleaned
    if "reminder_minutes" in fields_set:
        if payload.reminder_minutes is None:
            unsets["reminder_minutes"] = ""
        else:
            updates["reminder_minutes"] = payload.reminder_minutes
    if "notify_enter" in fields_set:
        updates["notify_enter"] = bool(payload.notify_enter)
    if "notify_exit" in fields_set:
        updates["notify_exit"] = bool(payload.notify_exit)

    candidate = {**doc, **updates}
    for key in unsets:
        candidate.pop(key, None)

    time_key_value = _time_key(
        candidate.get("time"),
        candidate.get("repeat_option", doc.get("repeat_option", "none")),
        candidate.get("weekdays", doc.get("weekdays", [])),
    )
    if time_key_value:
        updates["time_key"] = time_key_value
    else:
        unsets["time_key"] = ""

    now = datetime.now(timezone.utc)
    updates["updated_at"] = now

    update_ops = {}
    if updates:
        update_ops["$set"] = updates
    if unsets:
        update_ops["$unset"] = unsets
    if update_ops:
        await db[COLLECTION].update_one({"_id": doc["_id"]}, update_ops)
        doc.update(updates)
        for key in unsets:
            doc.pop(key, None)

    return _serialize_notification(doc)


@router.patch("/{abc_id}/{setting_id}/time")
async def update_notification_time(
    abc_id: str,
    setting_id: str,
    payload: NotificationTimeUpdate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    doc = await _get_notification_or_404(db, user_id, abc_id, setting_id)
    time_value = _normalize_time(payload.time)
    if not time_value:
        raise HTTPException(status_code=400, detail="Invalid time value")
    repeat_option = _normalize_repeat_option(payload.repeat_option or doc.get("repeat_option"))
    weekdays_source = payload.weekdays if payload.weekdays is not None else doc.get("weekdays", [])
    weekdays = _normalize_weekdays(weekdays_source)
    time_key_value = _time_key(time_value, repeat_option, weekdays)

    updates = {
        "time": time_value,
        "repeat_option": repeat_option,
        "weekdays": weekdays,
        "updated_at": datetime.now(timezone.utc),
    }
    update_ops = {"$set": updates}
    if time_key_value:
        updates["time_key"] = time_key_value
    else:
        update_ops["$unset"] = {"time_key": ""}

    await db[COLLECTION].update_one({"_id": doc["_id"]}, update_ops)
    doc.update(updates)
    if not time_key_value:
        doc.pop("time_key", None)
    return _serialize_notification(doc)


@router.patch("/{abc_id}/{setting_id}/description")
async def update_notification_description(
    abc_id: str,
    setting_id: str,
    payload: NotificationDescriptionUpdate,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    doc = await _get_notification_or_404(db, user_id, abc_id, setting_id)
    cleaned = _clean_text(payload.description)
    updates = {"updated_at": datetime.now(timezone.utc)}
    update_ops: dict = {}
    if cleaned is None:
        update_ops["$unset"] = {"description": ""}
        doc.pop("description", None)
    else:
        updates["description"] = cleaned
        update_ops["$set"] = updates
        doc["description"] = cleaned
    if "$set" not in update_ops:
        update_ops["$set"] = updates
    await db[COLLECTION].update_one({"_id": doc["_id"]}, update_ops)
    doc.update(updates)
    return _serialize_notification(doc)


@router.delete("/{abc_id}/{setting_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    abc_id: str,
    setting_id: str,
    db=Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    doc = await _get_notification_or_404(db, user_id, abc_id, setting_id)
    await db[COLLECTION].delete_one({"_id": doc["_id"]})
    return Response(status_code=status.HTTP_204_NO_CONTENT)
