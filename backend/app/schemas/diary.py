from datetime import datetime
from typing import List, Optional, Any
from pydantic import BaseModel, Field


class DiaryBase(BaseModel):
    group_id: int = Field(..., alias="group_Id")
    activating_events: str = Field(..., alias="activating_events")
    belief: List[str] = Field(default_factory=list)
    consequence_p: List[str] = Field(default_factory=list)
    consequence_e: List[str] = Field(default_factory=list)
    consequence_b: List[str] = Field(default_factory=list)
    sud_scores: List[int] = Field(default_factory=list, alias="sudScores")
    alternative_thoughts: List[Any] = Field(default_factory=list, alias="alternativeThoughts")
    alarms: List[Any] = Field(default_factory=list)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address_name: Optional[str] = Field(None, alias="addressName")

    class Config:
        allow_population_by_field_name = True


class DiaryCreate(DiaryBase):
    pass


class DiaryUpdate(BaseModel):
    group_id: Optional[int] = Field(None, alias="group_Id")
    activating_events: Optional[str] = Field(None, alias="activating_events")
    belief: Optional[List[str]] = None
    consequence_p: Optional[List[str]] = None
    consequence_e: Optional[List[str]] = None
    consequence_b: Optional[List[str]] = None
    sud_scores: Optional[List[int]] = Field(None, alias="sudScores")
    alternative_thoughts: Optional[List[Any]] = Field(None, alias="alternativeThoughts")
    alarms: Optional[List[Any]] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address_name: Optional[str] = Field(None, alias="addressName")

    class Config:
        allow_population_by_field_name = True


class DiaryResponse(DiaryBase):
    diary_id: str = Field(..., alias="diaryId")
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime = Field(..., alias="updatedAt")

    class Config:
        allow_population_by_field_name = True
