from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class EnrollmentStatus(str, Enum):
    active = "active"
    dropped = "dropped"
    completed = "completed"
    failed = "failed"


class Enrollment(BaseModel):
    """Student–course link stored in the `enrollments` collection."""
    id: Optional[str] = Field(default=None, alias="_id")
    student_id: str                  # ref → users._id (student)
    course_id: str                   # ref → courses._id
    status: EnrollmentStatus = EnrollmentStatus.active
    grade: Optional[str] = None      # e.g. A, B+, F
    grade_points: Optional[float] = None
    enrolled_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
