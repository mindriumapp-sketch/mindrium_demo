from datetime import datetime, timezone
from typing import List, Optional, Any
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from schemas.relaxation import (
    RelaxationLogEntry,
    RelaxationTaskCreate,
    RelaxationTaskResponse,
    RelaxationScoreUpdate,
)

from db.mongo import get_db
from core.security import get_current_user
from models.user import USER_COLLECTION


router = APIRouter(prefix="/users/me", tags=["relaxation_tasks"])

USERS_COLLECTION = USER_COLLECTION


# ========= 공통 유틸 =========

def _ensure_tz(dt: Optional[datetime]) -> datetime:
    """timezone 없는 datetime은 UTC로 맞춰줌"""
    if dt is None:
        return datetime.now(timezone.utc)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def _parse_datetime_value(value: Any, fallback: Optional[datetime] = None) -> datetime:
    """문자열/None 섞여 있어도 datetime으로 파싱"""
    if isinstance(value, datetime):
        return _ensure_tz(value)
    if isinstance(value, str):
        try:
            # ISO 8601 문자열 대응 (Z → +00:00)
            return _ensure_tz(datetime.fromisoformat(value.replace("Z", "+00:00")))
        except Exception:
            pass
    if fallback is not None:
        return _ensure_tz(fallback)
    return datetime.now(timezone.utc)


async def _get_user_or_404(db, user_id: str) -> dict:
    user = await db[USERS_COLLECTION].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def _serialize_task(doc: dict) -> dict:
    """Mongo 도큐먼트를 API 응답 형태로 변환"""
    return {
        "relax_id": doc.get("relax_id", ""),
        "task_id": doc.get("task_id", ""),
        "week_number": doc.get("week_number"),
        "start_time": _parse_datetime_value(doc.get("start_time")),
        "end_time": (
            _parse_datetime_value(doc.get("end_time"))
            if doc.get("end_time") is not None
            else None
        ),
        "logs": [
            RelaxationLogEntry(
                action=entry.get("action", ""),
                timestamp=_parse_datetime_value(entry.get("timestamp")),
                elapsed_seconds=int(entry.get("elapsed_seconds", 0)),
            )
            for entry in (doc.get("logs") or [])
            if isinstance(entry, dict)
        ],

        # ✅ 새 필드들
        "latitude": doc.get("latitude"),
        "longitude": doc.get("longitude"),
        "address_name": doc.get("address_name"),
        "duration_time": doc.get("duration_time"),
        "relaxation_score": doc.get("relaxation_score"),
    }


# ========= Endpoints =========

@router.post(
    "/relaxation_tasks",
    response_model=RelaxationTaskResponse,
    status_code=status.HTTP_201_CREATED,
    summary="이완 세션 로그 생성/수정",
)
async def update_relaxation_task(
        payload: RelaxationTaskCreate,
        current_user: dict = Depends(get_current_user),
        db=Depends(get_db),
):
    """
    이완 세션 로그를 저장합니다.
    - 같은 **relax_id**로 여러 번 호출되면 → 기존 항목을 **덮어쓰기(upsert)** 합니다.
    - 필드 이름은 전부 Flutter 쪽에서 쓰는 그대로:
      - relax_id, task_id, week_number, start_time, end_time, logs[…]
      - latitude, longitude, address_name, duration_time (optional)
    """
    user_id = current_user["_id"]
    user = await _get_user_or_404(db, user_id)

    # 기존 relaxation_tasks 배열 가져오기
    tasks = list(user.get("relaxation_tasks", []))

    # 1) relaxId가 안 들어오면 → "create 전용" branch
    if payload.relax_id is None:
        new_relax_id = f"relax_{uuid.uuid4().hex[:6]}"
        existing_score = None
        existing_idx = -1
    else:
        # 2) relax_id가 들어오면 → update 시도
        new_relax_id = payload.relax_id
        existing_idx = -1
        for idx, t in enumerate(tasks):
            if t.get("relax_id") == new_relax_id:
                existing_idx = idx
                break

        if existing_idx >= 0:
            existing_score = tasks[existing_idx].get("relaxation_score")
        else:
            # 없는 relaxId로 업데이트 시도 → 404
            raise HTTPException(
                status_code=404,
                detail="Relaxation session not found for update",
            )

    log_doc = {
        "relax_id": new_relax_id,
        "task_id": payload.task_id,
        "week_number": payload.week_number,
        "start_time": _ensure_tz(payload.start_time),
        "end_time": _ensure_tz(payload.end_time) if payload.end_time is not None else None,
        "logs": [
            {
                "action": entry.action,
                "timestamp": _ensure_tz(entry.timestamp),
                "elapsed_seconds": entry.elapsed_seconds,
            }
            for entry in payload.logs
        ],

        # ✅ 새 필드들
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "address_name": payload.address_name,
        "duration_time": payload.duration_time,
        "relaxation_score": existing_score,  # 점수는 다른 화면에서 업데이트
    }

    if existing_idx >= 0:
        tasks[existing_idx] = log_doc
    else:
        tasks.append(log_doc)

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"relaxation_tasks": tasks}},
    )

    return RelaxationTaskResponse(**_serialize_task(log_doc))


@router.get(
    "/relaxation_tasks",
    response_model=List[RelaxationTaskResponse],
    summary="이완 세션 로그 목록 조회",
)
async def list_relaxation_tasks(
        week_number: Optional[int] = None,
        task_id: Optional[str] = None,
        current_user: dict = Depends(get_current_user),
        db=Depends(get_db),
):
    """
    사용자의 이완 세션 로그를 모두 조회합니다.

    - `week_number` 쿼리 파라미터로 특정 주차만 필터링 가능
    - `task_id` 쿼리 파라미터로 특정 task_id만 필터링 가능 (예: 특정 알람 ID)
    - start_time 기준 **최신순** 정렬
    """
    user_id = current_user["_id"]
    user = await _get_user_or_404(db, user_id)

    tasks = list(user.get("relaxation_tasks", []))

    # 주차 필터링 (선택)
    if week_number is not None:
        tasks = [
            t for t in tasks
            if t.get("week_number") is not None
               and int(t.get("week_number")) == int(week_number)
        ]

        # taskId 필터링 (선택)
    if task_id is not None:
        tasks = [
            t for t in tasks
            if t.get("task_id") == task_id
        ]

    # start_time 기준 최신순 정렬
    def _key(doc: dict) -> datetime:
        return _parse_datetime_value(doc.get("start_time"))

    tasks.sort(key=_key, reverse=True)

    return [RelaxationTaskResponse(**_serialize_task(t)) for t in tasks]


@router.get(
    "/relaxation_tasks/latest",
    response_model=Optional[RelaxationTaskResponse],
    summary="해당 주차 이완 로그 중 가장 최근 1개 조회",
)
async def get_latest_relaxation_task(
        week_number: Optional[int] = None,
        task_id: Optional[str] = None,      # ✅ 추가
        current_user: dict = Depends(get_current_user),
        db=Depends(get_db),
):
    """
    - week_number가 주어지면: 해당 주차(weekNumber)의 이완 로그 중 **가장 최근 1개**
    - task_id가 주어지면: 해당 taskId의 로그 중 **가장 최근 1개**
    - 둘 다 주어지면: 둘 다 만족하는 로그 중 가장 최근 1개
    - 아무 조건도 없으면: 전체 로그 중 가장 최근 1개
    - 로그가 전혀 없으면: `null` 반환
    """
    user_id = current_user["_id"]
    user = await _get_user_or_404(db, user_id)

    tasks = list(user.get("relaxation_tasks", []))

    # 주차 필터링 (선택)
    if week_number is not None:
        tasks = [
            t for t in tasks
            if t.get("week_number") is not None
               and int(t.get("week_number")) == int(week_number)
        ]

    if task_id is not None:
        tasks = [
            t for t in tasks
            if t.get("task_id") == task_id
        ]

    if not tasks:
        return None  # front에서 null 체크해서 "아직 안 함"으로 판단

    # start_time 기준으로 가장 최근 것
    def _key(doc: dict) -> datetime:
        return _parse_datetime_value(doc.get("start_time"))

    latest = max(tasks, key=_key)

    return RelaxationTaskResponse(**_serialize_task(latest))


@router.patch(
    "/relaxation_tasks/{relax_id}/score",
    response_model=RelaxationTaskResponse,
    summary="이완 점수(relaxation_score) 업데이트",
)
async def update_relaxation_score(
        relax_id: str,
        payload: RelaxationScoreUpdate,
        current_user: dict = Depends(get_current_user),
        db=Depends(get_db),
):
    """
    다른 화면에서 측정한 이완 점수(relaxation_score)를 업데이트한다.

    - path param의 `relax_id`와 일치하는 세션을 찾는다.
    - 찾으면 해당 항목의 `relaxation_score`만 변경.
    """
    user_id = current_user["_id"]
    user = await _get_user_or_404(db, user_id)

    tasks = list(user.get("relaxation_tasks", []))
    target_idx = -1
    for idx, t in enumerate(tasks):
        if t.get("relax_id") == relax_id:
            target_idx = idx
            break

    if target_idx < 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Relaxation session not found",
        )

    target = tasks[target_idx]
    target["relaxation_score"] = payload.relaxation_score

    tasks[target_idx] = target

    await db[USERS_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"relaxation_tasks": tasks}},
    )

    return RelaxationTaskResponse(**_serialize_task(target))
