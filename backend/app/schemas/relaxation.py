from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class RelaxationLogEntry(BaseModel):
    """logs 안에 들어가는 개별 이벤트"""
    action: str
    timestamp: datetime
    elapsed_seconds: int = Field(..., ge=0)


class RelaxationTaskCreate(BaseModel):
    """
    Flutter에서 보내는 payload
    """
    relax_id: Optional[str] = None
    task_id: str
    week_number: Optional[int] = Field(None, ge=1)
    start_time: datetime
    end_time: Optional[datetime] = None
    logs: List[RelaxationLogEntry] = Field(default_factory=list)

    # ✅ 새로 추가된 필드들 (nullable)
    latitude: Optional[float] = Field(
        default=None,
        description="위도 (optional)",
    )
    longitude: Optional[float] = Field(
        default=None,
        description="경도 (optional)",
    )
    address_name: Optional[str] = Field(
        default=None,
        description="주소명 (optional)",
    )
    duration_time: Optional[int] = Field(
        default=None,
        ge=0,
        description="이완 연습 실제 수행 시간 (초/밀리초 등, optional)",
    )


class RelaxationTaskResponse(BaseModel):
    """
    클라이언트로 돌려주는 응답
    (Mongo에 저장된 구조 그대로)
    """
    relax_id: str
    task_id: str
    week_number: Optional[int] = None
    start_time: datetime
    end_time: Optional[datetime] = None
    logs: List[RelaxationLogEntry]

    # ✅ 같은 필드들 응답에도 포함
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address_name: Optional[str] = None
    duration_time: Optional[int] = None

    # ✅ 점수는 나중에 업데이트되므로 optional
    relaxation_score: Optional[float] = Field(
        default=None,
        description="이완 만족도/점수 (다른 화면에서 측정)",
    )


class RelaxationScoreUpdate(BaseModel):
    """
    이완 점수만 업데이트할 때 사용하는 모델
    """
    relaxation_score: float = Field(
        None,
        description="이완 점수 (0~5)",
    )
