from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class StudentProfile(BaseModel):
    """Extended profile stored in the `students` collection."""
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str                     # ref → users._id
    student_id: str                  # college-issued student number
    department: str
    year: int                        # academic year (1-4)
    semester: int                    # 1 or 2
    gpa: Optional[float] = None
    enrolled_course_ids: List[str] = Field(default_factory=list)  # ref → courses._id
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
