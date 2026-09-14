from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


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
    college_id: Optional[str] = None  # e.g. student/employee ID

    class Config:
        populate_by_name = True
