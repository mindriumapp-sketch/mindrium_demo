from typing import List, Optional
from pydantic import BaseModel, Field


class NotificationBase(BaseModel):
    time: Optional[str] = Field(None, alias="time")
    repeat_option: Optional[str] = Field("none", alias="repeat_option")
    weekdays: List[int] = Field(default_factory=list, alias="weekdays")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location: Optional[str] = None
    description: Optional[str] = None
    cause: Optional[str] = None
    reminder_minutes: Optional[int] = Field(None, alias="reminder_minutes")
    notify_enter: bool = Field(False, alias="notify_enter")
    notify_exit: bool = Field(False, alias="notify_exit")

    class Config:
        populate_by_name = True


class NotificationCreate(NotificationBase):
    pass


class NotificationUpdate(BaseModel):
    time: Optional[str] = None
    repeat_option: Optional[str] = Field(None, alias="repeat_option")
    weekdays: Optional[List[int]] = Field(None, alias="weekdays")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location: Optional[str] = None
    description: Optional[str] = None
    cause: Optional[str] = None
    reminder_minutes: Optional[int] = Field(None, alias="reminder_minutes")
    notify_enter: Optional[bool] = Field(None, alias="notify_enter")
    notify_exit: Optional[bool] = Field(None, alias="notify_exit")

    class Config:
        populate_by_name = True


class NotificationTimeUpdate(BaseModel):
    time: str
    repeat_option: Optional[str] = Field(None, alias="repeat_option")
    weekdays: Optional[List[int]] = Field(None, alias="weekdays")

    class Config:
        populate_by_name = True


class NotificationDescriptionUpdate(BaseModel):
    description: str
