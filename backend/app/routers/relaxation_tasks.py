from datetime import datetime, timezone, timedelta
try:
    from zoneinfo import ZoneInfo
except ModuleNotFoundError:  # pragma: no cover
    ZoneInfo = None

from typing import List, Optional, Any
from bson import ObjectId
from fastapi import APIRouter, Depends, Header, HTTPException, status
from schemas.relaxation import (
    RelaxationLogEntry,
    RelaxationTaskCreate,
    RelaxationTaskResponse,
    RelaxationScoreUpdate,
)

from db.mongo import get_db
from core.security import decode_token


router = APIRouter(prefix="/relaxation_tasks", tags=["relaxation_tasks"])

COLLECTION = "relaxation_tasks"


# ========= 공통 유틸 =========

def _ensure_tz(dt: Optional[datetime]) -> datetime:
    """timezone 없는 datetime은 UTC로 맞춰줌"""
    if dt is None:
        return datetime.now(timezone.utc)
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def _get_kst_tz():
    if ZoneInfo is not None:
        try:
            return ZoneInfo("Asia/Seoul")
        except Exception:
            pass
    return timezone(timedelta(hours=9))


KST = _get_kst_tz()

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


async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")


def _serialize_task(doc: dict) -> dict:
    """Mongo 도큐먼트를 API 응답 형태로 변환 (응답은 한국시간 KST로 변환)"""
    # 원본을 UTC/naive → timezone 포함 datetime으로 먼저 맞추고
    start_utc = _parse_datetime_value(doc.get("start_time"))
    end_raw = doc.get("end_time")
    end_utc = (
        _parse_datetime_value(end_raw)
        if end_raw is not None
        else None
    )

    # 응답에는 KST로 변환해서 내보냄
    start_kst = start_utc.astimezone(KST)
    end_kst = end_utc.astimezone(KST) if end_utc is not None else None

    return {
        # Mongo의 _id(ObjectId)를 문자열로 내보내고, 클라이언트에서는 relax_id로 사용
        "relax_id": str(doc["_id"]),
        "task_id": doc.get("task_id"),
        "week_number": doc.get("week_number"),
        "start_time": start_kst,
        "end_time": end_kst,
        "logs": [
            RelaxationLogEntry(
                action=entry.get("action"),
                timestamp=_parse_datetime_value(entry.get("timestamp")).astimezone(KST),
                elapsed_seconds=int(entry.get("elapsed_seconds", 0)),
            )
            for entry in (doc.get("logs") or [])
            if isinstance(entry, dict)
        ],
        "latitude": doc.get("latitude"),
        "longitude": doc.get("longitude"),
        "address_name": doc.get("address_name"),
        "duration_time": doc.get("duration_time"),
        "relaxation_score": doc.get("relaxation_score"),
    }


# ========= Endpoints =========

@router.post(
    "",
    response_model=RelaxationTaskResponse,
    status_code=status.HTTP_201_CREATED,
    summary="이완 세션 로그 생성/수정 (별도 컬렉션)",
)
async def update_relaxation_task(
        payload: RelaxationTaskCreate,
        db=Depends(get_db),
        user_id: str = Depends(get_current_user_id),
):
    """
    이완 세션 로그를 저장합니다.
    - 같은 **relax_id**로 여러 번 호출되면 → 기존 항목을 **덮어쓰기(upsert)** 합니다.
    - 필드 이름은 전부 Flutter 쪽에서 쓰는 그대로:
      - relax_id, task_id, week_number, start_time, end_time, logs[…]
      - latitude, longitude, address_name, duration_time (optional)
    """
    collection = db[COLLECTION]

    # ✅ 새 세션 생성
    if payload.relax_id is None:
        log_doc = {
            "user_id": user_id,
            "task_id": payload.task_id,
            "week_number": payload.week_number,
            "start_time": _ensure_tz(payload.start_time),
            "end_time": (
                _ensure_tz(payload.end_time)
                if payload.end_time is not None
                else None
            ),
            "logs": [
                {
                    "action": entry.action,
                    "timestamp": _ensure_tz(entry.timestamp),
                    "elapsed_seconds": entry.elapsed_seconds,
                }
                for entry in payload.logs
            ],
            "latitude": payload.latitude,
            "longitude": payload.longitude,
            "address_name": payload.address_name,
            "duration_time": payload.duration_time,
            "relaxation_score": None,  # 점수는 나중에 별도 PATCH로
        }
        result = await collection.insert_one(log_doc)
        saved = await collection.find_one({"_id": result.inserted_id})
        return RelaxationTaskResponse(**_serialize_task(saved))

    # ✅ 기존 세션 업데이트 (autosave 등)
    try:
        obj_id = ObjectId(payload.relax_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid relax_id",
        )

    existing = await collection.find_one({"_id": obj_id, "user_id": user_id})
    if existing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Relaxation session not found for update",
        )

    existing_score = existing.get("relaxation_score")

    log_doc = {
        "user_id": user_id,
        "task_id": payload.task_id,
        "week_number": payload.week_number,
        "start_time": _ensure_tz(payload.start_time),
        "end_time": (
            _ensure_tz(payload.end_time)
            if payload.end_time is not None
            else None
        ),
        "logs": [
            {
                "action": entry.action,
                "timestamp": _ensure_tz(entry.timestamp),
                "elapsed_seconds": entry.elapsed_seconds,
            }
            for entry in payload.logs
        ],
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "address_name": payload.address_name,
        "duration_time": payload.duration_time,
        # 점수는 유지
        "relaxation_score": existing_score,
    }

    await collection.update_one(
        {"_id": obj_id, "user_id": user_id},
        {"$set": log_doc},
    )
    saved = await collection.find_one({"_id": obj_id, "user_id": user_id})
    return RelaxationTaskResponse(**_serialize_task(saved))


@router.get(
    "",
    response_model=List[RelaxationTaskResponse],
    summary="이완 세션 로그 목록 조회 (별도 컬렉션)",
)
async def list_relaxation_tasks(
        week_number: Optional[int] = None,
        task_id: Optional[str] = None,
        user_id: str = Depends(get_current_user_id),
        db=Depends(get_db),
):
    """
    사용자의 이완 세션 로그를 모두 조회합니다.

    - `week_number` 쿼리 파라미터로 특정 주차만 필터링 가능
    - `task_id` 쿼리 파라미터로 특정 task_id만 필터링 가능 (예: 특정 알람 ID)
    - start_time 기준 **최신순** 정렬
    """
    collection = db[COLLECTION]

    query: dict[str, Any] = {"user_id": user_id}
    if week_number is not None:
        query["week_number"] = int(week_number)
    if task_id is not None:
        query["task_id"] = task_id

    cursor = collection.find(query).sort("start_time", -1)

    tasks: List[RelaxationTaskResponse] = []
    async for doc in cursor:
        tasks.append(RelaxationTaskResponse(**_serialize_task(doc)))
    return tasks


@router.get(
    "/latest",
    response_model=Optional[RelaxationTaskResponse],
    summary="조건에 맞는 가장 최근 이완 로그 1개 조회 (별도 컬렉션)",
)
async def get_latest_relaxation_task(
        week_number: Optional[int] = None,
        task_id: Optional[str] = None,      # ✅ 추가
        user_id: str = Depends(get_current_user_id),
        db=Depends(get_db),
):
    """
    - week_number가 주어지면: 해당 주차(weekNumber)의 이완 로그 중 **가장 최근 1개**
    - task_id가 주어지면: 해당 taskId의 로그 중 **가장 최근 1개**
    - 둘 다 주어지면: 둘 다 만족하는 로그 중 가장 최근 1개
    - 아무 조건도 없으면: 전체 로그 중 가장 최근 1개
    - 로그가 전혀 없으면: `null` 반환
    """
    collection = db[COLLECTION]

    query: dict[str, Any] = {"user_id": user_id}
    if week_number is not None:
        query["week_number"] = int(week_number)
    if task_id is not None:
        query["task_id"] = task_id

    doc = await collection.find_one(query, sort=[("start_time", -1)])

    if not doc:
        return None

    return RelaxationTaskResponse(**_serialize_task(doc))


@router.patch(
    "/{relax_id}/score",
    response_model=RelaxationTaskResponse,
    summary="이완 점수(relaxation_score) 업데이트 (별도 컬렉션)",
)
async def update_relaxation_score(
        relax_id: str,
        payload: RelaxationScoreUpdate,
        user_id: str = Depends(get_current_user_id),
        db=Depends(get_db),
):
    """
    다른 화면에서 측정한 이완 점수(relaxation_score)를 업데이트한다.

    - path param의 `relax_id`와 일치하는 세션을 찾는다.
    - 찾으면 해당 항목의 `relaxation_score`만 변경.
    """
    collection = db[COLLECTION]

    try:
        obj_id = ObjectId(relax_id)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid relax_id",
        )

    result = await collection.find_one_and_update(
        {"_id": obj_id, "user_id": user_id},
        {"$set": {"relaxation_score": payload.relaxation_score}},
        return_document=True,
    )

    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Relaxation session not found",
        )

    return RelaxationTaskResponse(**_serialize_task(result))