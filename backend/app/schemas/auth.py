from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    name: str
    gender: str | None = None
    code: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RefreshRequest(BaseModel):
    refresh_token: str

class EmailVerifyRequest(BaseModel):
    token: str

class PasswordResetStartRequest(BaseModel):
    email: EmailStr

class PasswordResetFinishRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=6)

class PasswordChangeRequest(BaseModel):
    current_password: str
    new_password: str = Field(min_length=6)
