from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class AttendanceRecord(BaseModel):
    student_id: str
    status: str  # present, absent, late

class MarkAttendanceRequest(BaseModel):
    course_id: str
    records: List[AttendanceRecord]
    date: Optional[str] = None
    notes: Optional[str] = None
