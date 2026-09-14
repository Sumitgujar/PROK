from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class Course(BaseModel):
    """Course catalog entry stored in the `courses` collection."""
    id: Optional[str] = Field(default=None, alias="_id")
    course_code: str                 # e.g. CS301
    title: str
    description: Optional[str] = None
    department: str
    credits: int = 3
    teacher_id: Optional[str] = None  # ref → users._id
    semester: int
    year: int
    max_students: int = 60
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
