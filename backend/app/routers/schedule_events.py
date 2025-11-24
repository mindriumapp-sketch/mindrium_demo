from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from db.mongo import get_db
from core.security import get_current_user


COLLECTION_NAME = "schedule_events"

router = APIRouter(prefix="/schedule-events", tags=["schedule-events"])


class ScheduleEventTask(BaseModel):
    label: str = Field(..., min_length=1, description="실천할 행동 이름")
    chip_id: Optional[str] = Field(
        None, description="연결된 custom tag chip_id (선택)"
    )


class ScheduleEventCreate(BaseModel):
    start_date: date = Field(..., description="계획 시작일")
    end_date: date = Field(..., description="계획 종료일 (포함)")
    tasks: List[ScheduleEventTask] = Field(
        default_factory=list, description="실천할 행동 목록"
    )


class ScheduleEventResponse(ScheduleEventCreate):
    event_id: str
    created_at: datetime
    updated_at: datetime


def _serialize_event(doc: dict) -> ScheduleEventResponse:
    start_date = doc.get("start_date")
    end_date = doc.get("end_date")
    if isinstance(start_date, str):
        start_date = date.fromisoformat(start_date)
    if isinstance(end_date, str):
        end_date = date.fromisoformat(end_date)

    tasks = [
        ScheduleEventTask(**task) if isinstance(task, dict) else task
        for task in doc.get("tasks", [])
    ]

    return ScheduleEventResponse(
        event_id=doc["event_id"],
        start_date=start_date,
        end_date=end_date,
        tasks=tasks,
        created_at=doc.get("created_at"),
        updated_at=doc.get("updated_at"),
    )


async def _get_event_or_404(db, user_id: str, event_id: str) -> dict:
    event = await db[COLLECTION_NAME].find_one(
        {"user_id": user_id, "event_id": event_id}
    )
    if not event:
        raise HTTPException(status_code=404, detail="이벤트를 찾을 수 없습니다")
    return event


@router.post(
    "",
    response_model=ScheduleEventResponse,
    status_code=status.HTTP_201_CREATED,
    summary="캘린더 이벤트 생성",
)
async def create_schedule_event(
    payload: ScheduleEventCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    user_id = current_user["_id"]
    now = datetime.now(timezone.utc)
    event_id = f"se_{uuid.uuid4().hex[:8]}"

    doc = {
        "event_id": event_id,
        "user_id": user_id,
        "start_date": payload.start_date.isoformat(),
        "end_date": payload.end_date.isoformat(),
        "tasks": [task.dict() for task in payload.tasks],
        "created_at": now,
        "updated_at": now,
    }

    await db[COLLECTION_NAME].insert_one(doc)
    return _serialize_event(doc)


@router.get(
    "",
    response_model=List[ScheduleEventResponse],
    summary="사용자 캘린더 이벤트 목록",
)
async def list_schedule_events(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    user_id = current_user["_id"]
    query: Dict[str, Any] = {"user_id": user_id}

    if start_date or end_date:
        date_query: Dict[str, Any] = {}
        if start_date:
            date_query["$gte"] = start_date.isoformat()
        if end_date:
            date_query["$lte"] = end_date.isoformat()
        query["start_date"] = date_query

    cursor = (
        db[COLLECTION_NAME]
        .find(query)
        .sort("start_date", 1)
    )
    events = await cursor.to_list(length=None)
    return [_serialize_event(doc) for doc in events]


@router.put(
    "/{event_id}",
    response_model=ScheduleEventResponse,
    summary="캘린더 이벤트 수정",
)
async def update_schedule_event(
    event_id: str,
    payload: ScheduleEventCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    user_id = current_user["_id"]
    event = await _get_event_or_404(db, user_id, event_id)
    now = datetime.now(timezone.utc)

    update_doc = {
        "start_date": payload.start_date.isoformat(),
        "end_date": payload.end_date.isoformat(),
        "tasks": [task.dict() for task in payload.tasks],
        "updated_at": now,
    }

    await db[COLLECTION_NAME].update_one(
        {"user_id": user_id, "event_id": event_id},
        {"$set": update_doc},
    )
    event.update(update_doc)
    return _serialize_event(event)


@router.delete(
    "/{event_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="캘린더 이벤트 삭제",
)
async def delete_schedule_event(
    event_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    user_id = current_user["_id"]
    result = await db[COLLECTION_NAME].delete_one(
        {"user_id": user_id, "event_id": event_id}
    )
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="이벤트를 찾을 수 없습니다")
    return None

