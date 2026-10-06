from enum import Enum
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class UserRole(str, Enum):
    student = "student"
    teacher = "teacher"
    admin = "admin"


class UserInDB(BaseModel):
    """Represents a user document as stored in MongoDB."""
    id: Optional[str] = Field(default=None, alias="_id")
    name: str
    email: str
    hashed_password: str
    role: UserRole = UserRole.student
    is_active: bool = True
    college_id: Optional[str] = None

    class Config:
        populate_by_name = True


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    role: str = "student"
    full_name: str
    college_id: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict
