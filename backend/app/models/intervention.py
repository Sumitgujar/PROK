from pydantic import BaseModel
from typing import Optional


class InterventionCreate(BaseModel):
    student_id: str
    issue: str
    recommendation: str
    action: str
    status: str = "OPEN"
    outcome: Optional[str] = None


class InterventionUpdate(BaseModel):
    issue: Optional[str] = None
    recommendation: Optional[str] = None
    action: Optional[str] = None
    status: Optional[str] = None
    outcome: Optional[str] = None
