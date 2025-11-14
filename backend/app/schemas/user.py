from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime

class SudScore(BaseModel):
    initial: int
    update_score: Optional[int] = None
    updated_at: Optional[datetime] = None
    created_at: datetime

class RelaxationEvaluation(BaseModel):
    created_at: datetime
    week_number: int
    latitude: float
    longitude: float

class AlternativeThought(BaseModel):
    emotion_tag_id: str
    thought: str

class ConfrontAvoidLog(BaseModel):
    type: str
    comment: str
    timestamp: datetime

class TagItem(BaseModel):
    tag_id: str
    category: str
    type: Optional[str] = None

class AlarmConfig(BaseModel):
    start_time: Optional[str] = None
    alert_latitude: Optional[float] = None
    alert_longitude: Optional[float] = None
    location_desc: Optional[str] = None
    on_enter: Optional[bool] = None
    on_exit: Optional[bool] = None
    repeat_dates: Optional[list[str]] = None
    created_at: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class DiaryItem(BaseModel):
    diary_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    sud_score: Optional[SudScore] = None
    relaxation_evaluation: Optional[RelaxationEvaluation] = None
    alternative_thoughts: List[AlternativeThought] = []
    confront_avoid_logs: List[ConfrontAvoidLog] = []
    tags: List[TagItem] = []
    alarm: Optional[AlarmConfig] = None

class WorryGroup(BaseModel):
    group_id: str
    group_name: str
    description: Optional[str] = None
    character_id: Optional[str] = None
    archived: bool = False
    archived_at: Optional[datetime] = None
    average_sud: Optional[int] = None
    created_at: datetime
    diaries: List[DiaryItem] = []

class RelaxationTask(BaseModel):
    task_id: str
    start_time: datetime
    end_time: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    week_number: Optional[int] = None
    alert_time: Optional[str] = None

class SurveyItem(BaseModel):
    type: str
    title: str
    date: str
    description: Optional[str] = None

class CustomTag(BaseModel):
    tag_key: str
    tag_id: str
    name: str
    category: str
    type: Optional[str] = None

class UserBase(BaseModel):
    email: EmailStr
    name: str
    gender: Optional[str] = None

class UserCreate(UserBase):
    password: str = Field(min_length=6)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserOut(UserBase):
    _id: str
    survey_completed: bool
    email_verified: bool
    worry_groups: List[WorryGroup]
    relaxation_tasks: List[RelaxationTask]
    surveys: List[SurveyItem]
    custom_tags: List[CustomTag]
    created_at: datetime

class UserMe(UserBase):
    _id: str
    survey_completed: bool
    email_verified: bool
    created_at: Optional[datetime] = None

class UpdateUser(BaseModel):
    name: Optional[str] = None
    gender: Optional[str] = None

class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenRefreshRequest(BaseModel):
    refresh_token: str

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str = Field(min_length=6)
