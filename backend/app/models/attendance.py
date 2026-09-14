from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date
from enum import Enum


# ── Attendance Session ───────────────────────────────────────────────────────

class AttendanceSession(BaseModel):
    """A single class session stored in `attendance_sessions`."""
    id: Optional[str] = Field(default=None, alias="_id")
    course_id: str                   # ref → courses._id
    teacher_id: str                  # ref → users._id (teacher)
    date: str                        # ISO date string YYYY-MM-DD
    topic: Optional[str] = None
    duration_minutes: int = 60
    is_open: bool = True             # False once teacher closes the session
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


# ── Attendance Record ────────────────────────────────────────────────────────

class AttendanceStatus(str, Enum):
    present = "present"
    absent = "absent"
    late = "late"
    excused = "excused"


class AttendanceRecord(BaseModel):
    """Per-student attendance record stored in `attendance_records`."""
    id: Optional[str] = Field(default=None, alias="_id")
    session_id: str                  # ref → attendance_sessions._id
    student_id: str                  # ref → users._id (student)
    status: AttendanceStatus = AttendanceStatus.absent
    marked_at: datetime = Field(default_factory=datetime.utcnow)
    note: Optional[str] = None       # optional teacher note

    class Config:
        populate_by_name = True
