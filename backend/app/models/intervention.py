from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class InterventionType(str, Enum):
    attendance = "attendance"        # low attendance warning
    academic = "academic"            # low GPA / failing grades
    behavioural = "behavioural"
    financial = "financial"
    wellness = "wellness"


class InterventionStatus(str, Enum):
    open = "open"
    in_progress = "in_progress"
    resolved = "resolved"
    escalated = "escalated"


class Intervention(BaseModel):
    """Academic/wellness intervention stored in `interventions`."""
    id: Optional[str] = Field(default=None, alias="_id")
    student_id: str                  # ref → users._id (student)
    intervention_type: InterventionType
    description: str
    status: InterventionStatus = InterventionStatus.open
    created_by: str                  # ref → users._id (teacher or admin)
    assigned_to: Optional[str] = None  # ref → users._id
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None
    resolution_note: Optional[str] = None

    class Config:
        populate_by_name = True
