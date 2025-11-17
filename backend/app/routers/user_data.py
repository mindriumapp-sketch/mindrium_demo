"""
사용자 데이터 관리 API
- 핵심 가치 (core value)
- 설문 데이터
- 주차별 진행도
- 사용자 정보 업데이트
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone
from pydantic import BaseModel, Field
import uuid

from db.mongo import get_db
from core.security import get_current_user
from models.user import USER_COLLECTION

router = APIRouter(prefix="/users/me", tags=["user-data"])


# ============= Schemas =============

class CoreValueUpdate(BaseModel):
    """핵심 가치 업데이트 요청"""
    value_goal: str = Field(..., min_length=1, max_length=500, description="사용자의 핵심 가치")


class CoreValueResponse(BaseModel):
    """핵심 가치 응답"""
    value_goal: Optional[str] = None
    updated_at: Optional[datetime] = None


class SurveyCreate(BaseModel):
    """설문 추가 요청"""
    survey_type: str = Field(..., alias="type", description="설문 유형 ID")
    description: Optional[str] = Field(None, description="설문 설명 (DB에는 저장되지 않음)")
    answers: Optional[Dict[str, Any]] = Field(None, description="설문 응답 데이터")


class SurveyResponse(BaseModel):
    """설문 응답"""
    type: str
    completed_at: str
    answers: Optional[Dict[str, Any]] = None


class WeekProgress(BaseModel):
    """주차별 진행도"""
    week_number: int = Field(..., ge=1, le=8, description="주차 (1-8)")
    completed: bool = Field(default=False, description="완료 여부")
    completed_at: Optional[datetime] = Field(None, description="완료 시각")
    progress_percent: Optional[int] = Field(None, ge=0, le=100, description="진행률 (%)")


class ProgressUpdate(BaseModel):
    """진행도 업데이트 요청"""
    week_number: int = Field(..., ge=1, le=8)
    completed: bool = Field(default=False)
    progress_percent: Optional[int] = Field(None, ge=0, le=100)


class UserDataResponse(BaseModel):
    """종합 사용자 데이터 응답"""
    value_goal: Optional[str] = None
    before_survey_completed: bool = False
    current_week: int = 1
    week_progress: List[WeekProgress] = []
    total_diaries: int = 0
    total_relaxations: int = 0


class CustomTagCreate(BaseModel):
    text: str = Field(..., min_length=1, max_length=100)
    type: str = Field(..., min_length=1, max_length=10)


class CustomTagResponse(BaseModel):
    chip_id: str
    text: str
    type: str
    created_at: datetime


class ClassificationQuizResult(BaseModel):
    """분류 퀴즈 결과"""
    text: str
    correct_type: str
    user_choice: str
    is_correct: bool


class ClassificationQuiz(BaseModel):
    """분류 퀴즈 전체 결과"""
    correct_count: int
    total_count: int
    results: List[ClassificationQuizResult]
    wrong_list: List[Dict[str, Any]]


class PracticeSessionCreate(BaseModel):
    """주차별 연습 세션 생성 요청 (3주차, 5주차 등)"""
    week_number: int = Field(..., ge=1, le=8, description="주차 (1-8)")
    negative_items: List[str] = Field(default_factory=list, description="부정적 항목 (3주차: 도움이 되지 않는 생각, 5주차: 회피 행동)")
    positive_items: List[str] = Field(default_factory=list, description="긍정적 항목 (3주차: 도움이 되는 생각, 5주차: 직면 행동)")
    classification_quiz: Optional[ClassificationQuiz] = Field(None, description="분류 퀴즈 결과")


class PracticeSessionResponse(BaseModel):
    """주차별 연습 세션 응답"""
    session_id: str
    week_number: int
    negative_items: List[str]
    positive_items: List[str]
    classification_quiz: Optional[ClassificationQuiz] = None
    created_at: datetime
    updated_at: datetime


# ============= API Endpoints =============

@router.get("/core-value", response_model=CoreValueResponse, summary="핵심 가치 조회")
async def get_core_value(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    현재 로그인한 사용자의 핵심 가치를 조회합니다.
    
    - **value_goal**: 사용자가 설정한 핵심 가치 문구
    - **updated_at**: 마지막 업데이트 시각
    """
    user_id = current_user["_id"]
    user = await db[USER_COLLECTION].find_one({"_id": user_id})
    
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    value_goal = user.get("value_goal")
    updated_at = user.get("value_goal_updated_at")

    if value_goal is None:
        value_goal = user.get("core_value")
    if updated_at is None:
        updated_at = user.get("core_value_updated_at")

    return CoreValueResponse(
        value_goal=value_goal,
        updated_at=updated_at
    )


@router.put("/core-value", response_model=CoreValueResponse, summary="핵심 가치 설정/수정")
async def update_core_value(
    data: CoreValueUpdate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    사용자의 핵심 가치를 설정하거나 수정합니다.
    
    - **value_goal**: 최대 500자까지 입력 가능
    - 자동으로 updated_at 타임스탬프 기록
    """
    user_id = current_user["_id"]
    now = datetime.now(timezone.utc)
    
    result = await db[USER_COLLECTION].update_one(
        {"_id": user_id},
        {
            "$set": {
                "value_goal": data.value_goal,
                "value_goal_updated_at": now,
            },
            "$unset": {
                "core_value": "",
                "core_value_updated_at": "",
            },
        }
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    return CoreValueResponse(
        value_goal=data.value_goal,
        updated_at=now
    )


@router.delete("/core-value", status_code=status.HTTP_204_NO_CONTENT, summary="핵심 가치 삭제")
async def delete_core_value(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    사용자의 핵심 가치를 삭제합니다.
    """
    user_id = current_user["_id"]
    
    result = await db[USER_COLLECTION].update_one(
        {"_id": user_id},
        {
            "$unset": {
                "value_goal": "",
                "value_goal_updated_at": "",
                "core_value": "",
                "core_value_updated_at": "",
            }
        }
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")


@router.get("/surveys", response_model=List[SurveyResponse], summary="설문 목록 조회")
async def get_surveys(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    사용자가 완료한 모든 설문 목록을 조회합니다.
    
    - 최신순으로 정렬되어 반환
    """
    user_id = current_user["_id"]
    user = await db[USER_COLLECTION].find_one({"_id": user_id})
    
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    surveys = user.get("surveys", [])
    # 최신순 정렬 (completed_at 기준, 과거 데이터 호환)
    surveys.sort(key=lambda x: x.get("completed_at") or x.get("date", ""), reverse=True)
    
    return surveys


@router.post("/surveys", response_model=SurveyResponse, status_code=status.HTTP_201_CREATED, summary="설문 추가")
async def add_survey(
    survey: SurveyCreate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    새로운 설문 결과를 추가합니다.
    
    - **type**: 고유한 설문 유형 (예: "GAD7_pre", "GAD7_post")
    - **title**: 설문 제목
    - **score**: 설문 점수 (선택사항)
    - **answers**: 설문 응답 데이터 (선택사항)
    """
    user_id = current_user["_id"]
    now = datetime.now(timezone.utc)
    
    survey_doc = {
        "type": survey.survey_type,
        "completed_at": now.isoformat(),
        "answers": survey.answers,
    }
    
    # 중복 체크: 동일한 type이 이미 있으면 업데이트
    user = await db[USER_COLLECTION].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    existing_surveys = user.get("surveys", [])
    survey_exists = False
    
    for i, s in enumerate(existing_surveys):
        if s.get("type") == survey.survey_type:
            existing_surveys[i] = survey_doc
            survey_exists = True
            break
    
    if not survey_exists:
        existing_surveys.append(survey_doc)
    
    # 데이터베이스 업데이트
    await db[USER_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"surveys": existing_surveys}}
    )
    
    # before_survey_completed 상태 업데이트 (GAD7_pre 설문 완료시)
    if survey.survey_type.lower() in ["gad7_pre", "before_survey"]:
        await db[USER_COLLECTION].update_one(
            {"_id": user_id},
            {"$set": {"survey_completed": True}}
        )
    
    return survey_doc


@router.get("/custom-tags", response_model=List[CustomTagResponse], summary="사용자 커스텀 태그 조회")
async def get_custom_tags(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    user_id = current_user["_id"]
    user = await db[USER_COLLECTION].find_one({"_id": user_id})

    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")

    tags = []
    for raw in user.get("custom_tags", []):
        created_at = raw.get("created_at")
        if isinstance(created_at, str):
            try:
                created_at = datetime.fromisoformat(created_at)
            except Exception:
                created_at = datetime.now(timezone.utc)
        elif created_at is None:
            created_at = datetime.now(timezone.utc)

        chip_id = raw.get("chip_id") or raw.get("tag_id") or ""

        tags.append(
            CustomTagResponse(
                chip_id=chip_id,
                text=raw.get("text", ""),
                type=raw.get("type", ""),
                created_at=created_at,
            )
        )

    return tags


@router.post(
    "/custom-tags",
    response_model=CustomTagResponse,
    status_code=status.HTTP_201_CREATED,
    summary="사용자 커스텀 태그 추가",
)
async def create_custom_tag(
    tag: CustomTagCreate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    user_id = current_user["_id"]
    allowed_types = {"A", "B", "CP", "CE", "CB"}
    if tag.type not in allowed_types:
        raise HTTPException(status_code=400, detail="허용되지 않은 태그 유형입니다")

    now = datetime.now(timezone.utc)
    chip_id = f"{tag.type.lower()}_{uuid.uuid4().hex[:4]}"
    tag_doc = {
        "chip_id": chip_id,
        "text": tag.text,
        "type": tag.type,
        "created_at": now,
    }

    user = await db[USER_COLLECTION].find_one({"_id": user_id}, {"custom_tags": 1})
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")

    tags = list(user.get("custom_tags", []))
    tags.append(tag_doc)

    await db[USER_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"custom_tags": tags}},
    )

    return CustomTagResponse(**tag_doc)


@router.get("/worry-groups/archived", summary="아카이브된 걱정 그룹 조회")
async def get_archived_worry_groups(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    사용자가 아카이브한 걱정(ABC) 그룹 목록을 반환합니다.
    """
    user_id = current_user["_id"]
    user = await db[USER_COLLECTION].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")

    def _iso(value):
        if isinstance(value, datetime):
            return value.isoformat()
        return value

    groups = []
    for group in user.get("worry_groups", []):
        if not group.get("archived"):
            continue
        groups.append({
            "group_id": group.get("group_id"),
            "group_title": group.get("group_name") or group.get("group_title"),
            "group_contents": group.get("description") or group.get("group_contents"),
            "character_id": group.get("character_id"),
            "created_at": _iso(group.get("created_at")),
            "archived_at": _iso(group.get("archived_at")),
            "average_sud": group.get("average_sud"),
        })

    groups.sort(
        key=lambda g: g.get("archived_at") or g.get("created_at") or "",
        reverse=True,
    )
    return groups


@router.get("/progress", response_model=UserDataResponse, summary="전체 진행도 조회")
async def get_user_progress(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    사용자의 전체 진행 상황을 조회합니다.
    
    - **value_goal**: 핵심 가치
    - **before_survey_completed**: 사전 설문 완료 여부
    - **current_week**: 현재 진행 중인 주차
    - **week_progress**: 주차별 진행도 (1-8주)
    - **total_diaries**: 작성한 다이어리 수
    - **total_relaxations**: 완료한 이완 훈련 수
    """
    user_id = current_user["_id"]
    user = await db[USER_COLLECTION].find_one({"_id": user_id})
    
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    # 주차별 진행도 계산
    week_progress_data = user.get("week_progress", [])
    if not week_progress_data:
        # 기본 8주차 데이터 생성
        week_progress_data = [
            {"week_number": i, "completed": False, "progress_percent": 0}
            for i in range(1, 9)
        ]
    
    # 현재 주차 계산 (가장 최근 미완료 주차)
    current_week = 1
    for week in week_progress_data:
        if not week.get("completed", False):
            current_week = week.get("week_number", 1)
            break
    else:
        current_week = 8  # 모두 완료시
    
    # 다이어리 및 이완 훈련 카운트
    total_diaries = len(user.get("diaries", []))
    total_relaxations = len(user.get("relaxation_tasks", []))
    
    value_goal = user.get("value_goal")
    if value_goal is None:
        value_goal = user.get("core_value")

    return UserDataResponse(
        value_goal=value_goal,
        before_survey_completed=user.get("survey_completed", False),
        current_week=current_week,
        week_progress=week_progress_data,
        total_diaries=total_diaries,
        total_relaxations=total_relaxations
    )


@router.put("/progress", response_model=WeekProgress, summary="주차 진행도 업데이트")
async def update_week_progress(
    progress: ProgressUpdate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    특정 주차의 진행도를 업데이트합니다.
    
    - **week_number**: 업데이트할 주차 (1-8)
    - **completed**: 완료 여부
    - **progress_percent**: 진행률 (0-100)
    """
    user_id = current_user["_id"]
    user = await db[USER_COLLECTION].find_one({"_id": user_id})
    
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    week_progress_data = user.get("week_progress", [])
    
    # 해당 주차 찾기 또는 생성
    week_found = False
    for week in week_progress_data:
        if week.get("week_number") == progress.week_number:
            week["completed"] = progress.completed
            week["progress_percent"] = progress.progress_percent
            if progress.completed:
                week["completed_at"] = datetime.now(timezone.utc)
            week_found = True
            break
    
    if not week_found:
        new_week = {
            "week_number": progress.week_number,
            "completed": progress.completed,
            "progress_percent": progress.progress_percent
        }
        if progress.completed:
            new_week["completed_at"] = datetime.now(timezone.utc)
        week_progress_data.append(new_week)
    
    # 주차 번호순 정렬
    week_progress_data.sort(key=lambda x: x.get("week_number", 0))
    
    # 데이터베이스 업데이트
    await db[USER_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"week_progress": week_progress_data}}
    )
    
    # 업데이트된 주차 데이터 찾아서 반환
    for week in week_progress_data:
        if week.get("week_number") == progress.week_number:
            return WeekProgress(**week)
    
    raise HTTPException(status_code=500, detail="진행도 업데이트 실패")


@router.post(
    "/practice-sessions",
    response_model=PracticeSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="주차별 연습 세션 추가",
)
async def create_practice_session(
    session: PracticeSessionCreate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    주차별 연습 세션을 추가합니다 (3주차, 5주차 등).
    
    - **week_number**: 주차 (1-8)
    - **negative_items**: 부정적 항목 리스트 (3주차: 도움이 되지 않는 생각, 5주차: 회피 행동)
    - **positive_items**: 긍정적 항목 리스트 (3주차: 도움이 되는 생각, 5주차: 직면 행동)
    - **classification_quiz**: 분류 퀴즈 결과 (선택사항)
    """
    user_id = current_user["_id"]
    now = datetime.now(timezone.utc)
    session_id = f"session_{uuid.uuid4().hex[:8]}"
    
    session_doc = {
        "session_id": session_id,
        "week_number": session.week_number,
        "negative_items": session.negative_items,
        "positive_items": session.positive_items,
        "classification_quiz": session.classification_quiz.dict() if session.classification_quiz else None,
        "created_at": now,
        "updated_at": now,
    }
    
    user = await db[USER_COLLECTION].find_one({"_id": user_id}, {"practice_sessions": 1})
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    sessions = list(user.get("practice_sessions", []))
    sessions.append(session_doc)
    
    await db[USER_COLLECTION].update_one(
        {"_id": user_id},
        {"$set": {"practice_sessions": sessions}},
    )
    
    return PracticeSessionResponse(**session_doc)


@router.get(
    "/practice-sessions",
    response_model=List[PracticeSessionResponse],
    summary="주차별 연습 세션 목록 조회",
)
async def get_practice_sessions(
    week_number: Optional[int] = None,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    주차별 연습 세션 목록을 조회합니다 (3주차, 5주차 등).
    
    - **week_number**: 주차로 필터링 (선택사항, 없으면 전체 조회)
    - 최신순으로 정렬되어 반환
    """
    user_id = current_user["_id"]
    user = await db[USER_COLLECTION].find_one({"_id": user_id})
    
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    sessions = user.get("practice_sessions", [])
    
    # 주차 필터링
    if week_number is not None:
        sessions = [s for s in sessions if s.get("week_number") == week_number]
    
    # 최신순 정렬
    def _parse_date(v):
        if isinstance(v, datetime):
            return v
        if isinstance(v, str):
            try:
                return datetime.fromisoformat(v.replace('Z', '+00:00'))
            except Exception:
                pass
        return datetime.fromutc(datetime(1970, 1, 1), timezone.utc)
    
    sessions.sort(
        key=lambda s: _parse_date(s.get("created_at") or s.get("updated_at")),
        reverse=True
    )
    
    return [PracticeSessionResponse(**s) for s in sessions]
