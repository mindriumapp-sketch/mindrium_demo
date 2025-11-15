from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class SudScoreCreate(BaseModel):
    diary_id: str = Field(..., alias="diaryId")
    before_sud: int = Field(..., alias="before_sud", ge=0, le=10)
    after_sud: Optional[int] = Field(None, alias="after_sud", ge=0, le=10)
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    class Config:
        populate_by_name = True


class SudScoreUpdate(BaseModel):
    before_sud: Optional[int] = Field(None, alias="before_sud", ge=0, le=10)
    after_sud: Optional[int] = Field(None, alias="after_sud", ge=0, le=10)
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    class Config:
        populate_by_name = True


class SudScoreResponse(BaseModel):
    sud_id: str = Field(..., alias="sud_id")
    diary_id: str = Field(..., alias="diary_id")
    before_sud: int = Field(..., alias="before_sud")
    after_sud: Optional[int] = Field(None, alias="after_sud")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: datetime = Field(..., alias="created_at")
    updated_at: datetime = Field(..., alias="updated_at")

    class Config:
        populate_by_name = True
