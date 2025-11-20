from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, Field


class ScreenTimeCreate(BaseModel):
    start_time: datetime = Field(..., description="Session start in UTC")
    end_time: datetime = Field(..., description="Session end in UTC")
    platform: Optional[Literal["android", "ios", "web", "desktop"]] = None


class ScreenTimeEntry(BaseModel):
    id: str = Field(..., description="Document identifier")
    start_time: datetime
    end_time: datetime
    duration_minutes: float
    created_at: datetime
    platform: Optional[str] = None


class ScreenTimeSummary(BaseModel):
    totalMinutes: float = 0
    todayMinutes: float = 0
    weekMinutes: float = 0
    sessions: int = 0
    lastEntryAt: Optional[datetime] = None
