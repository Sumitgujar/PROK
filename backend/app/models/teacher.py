from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class TeacherProfile(BaseModel):
    """Extended profile stored in the `teachers` collection."""
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str                     # ref → users._id
    employee_id: str
    department: str
    designation: str = "Lecturer"    # e.g. Assistant Professor, HOD
    subjects: List[str] = Field(default_factory=list)  # subject names taught
    course_ids: List[str] = Field(default_factory=list)  # ref → courses._id
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
