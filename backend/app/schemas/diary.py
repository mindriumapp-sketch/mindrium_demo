from datetime import datetime
from typing import List, Optional, Any, Dict
from pydantic import BaseModel, Field


class DiaryBase(BaseModel):
    group_id: int = Field(..., alias="group_Id")
    activating_events: str = Field(..., alias="activating_events")
    belief: List[str] = Field(default_factory=list)
    consequence_p: List[str] = Field(default_factory=list)
    consequence_e: List[str] = Field(default_factory=list)
    consequence_b: List[str] = Field(default_factory=list)
    sud_scores: List[Any] = Field(default_factory=list, alias="sudScores")
    alternative_thoughts: List[Any] = Field(default_factory=list, alias="alternativeThoughts")
    # real oddness(실제 믿음 강도) 기록: [{belief: str, before:int, after:int?, created_at, updated_at}]
    real_oddness: List[Any] = Field(default_factory=list, alias="realOddness")
    alarms: List[Any] = Field(default_factory=list)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address_name: Optional[str] = Field(None, alias="addressName")

    class Config:
        populate_by_name = True


class DiaryCreate(DiaryBase):
    pass


class DiaryUpdate(BaseModel):
    group_id: Optional[int] = Field(None, alias="group_Id")
    activating_events: Optional[str] = Field(None, alias="activating_events")
    belief: Optional[List[str]] = None
    consequence_p: Optional[List[str]] = None
    consequence_e: Optional[List[str]] = None
    consequence_b: Optional[List[str]] = None
    sud_scores: Optional[List[Any]] = Field(None, alias="sudScores")
    alternative_thoughts: Optional[List[Any]] = Field(None, alias="alternativeThoughts")
    real_oddness: Optional[List[Any]] = Field(None, alias="realOddness")
    alarms: Optional[List[Any]] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address_name: Optional[str] = Field(None, alias="addressName")

    class Config:
        populate_by_name = True


class DiaryResponse(DiaryBase):
    diary_id: str = Field(..., alias="diaryId")
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime = Field(..., alias="updatedAt")

    class Config:
        populate_by_name = True


class AlarmBase(BaseModel):
    time: Optional[str] = None
    location_desc: Optional[str] = Field(None, alias="location_desc")
    repeat_option: Optional[str] = Field(None, alias="repeat_option")
    weekdays: List[int] = Field(default_factory=list, alias="weekDays")
    reminder_minutes: Optional[int] = Field(None, alias="reminder_minutes")
    enter: bool = Field(False, alias="enter")
    exit: bool = Field(False, alias="exit")

    class Config:
        populate_by_name = True


class AlarmCreate(AlarmBase):
    pass


class AlarmUpdate(BaseModel):
    time: Optional[str] = None
    location_desc: Optional[str] = Field(None, alias="location_desc")
    repeat_option: Optional[str] = Field(None, alias="repeat_option")
    weekdays: Optional[List[int]] = Field(None, alias="weekDays")
    reminder_minutes: Optional[int] = Field(None, alias="reminder_minutes")
    enter: Optional[bool] = None
    exit: Optional[bool] = None

    class Config:
        populate_by_name = True


class AlarmResponse(AlarmBase):
    alarm_id: str = Field(..., alias="alarmId")
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime = Field(..., alias="updatedAt")

    class Config:
        populate_by_name = True
