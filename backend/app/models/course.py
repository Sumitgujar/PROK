from pydantic import BaseModel
from typing import List, Optional

class CourseCreate(BaseModel):
    title: str
    course_code: str
    department: str
    credits: int = 3
    description: str = ""
    teacher_id: Optional[str] = None
    tags: List[str] = []

class ProfileUpdate(BaseModel):
    skills: List[str] = []
    interests: List[str] = []
    career_goals: List[str] = []
