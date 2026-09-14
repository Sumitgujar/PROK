from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


# ── Scholarship listing ────────────────────────────────────────────────────────

class Scholarship(BaseModel):
    """Scholarship listing stored in the `scholarships` collection."""
    id: Optional[str] = Field(default=None, alias="_id")
    title: str
    description: Optional[str] = None
    provider: str                    # e.g. "Government of India"
    amount: Optional[float] = None   # INR
    eligibility: Optional[str] = None
    deadline: Optional[str] = None   # ISO date string YYYY-MM-DD
    tags: List[str] = Field(default_factory=list)   # e.g. ["merit", "need-based"]
    apply_url: Optional[str] = None
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


# ── Scholarship application ────────────────────────────────────────────────────

class ApplicationStatus(str, Enum):
    draft = "draft"
    submitted = "submitted"
    under_review = "under_review"
    approved = "approved"
    rejected = "rejected"


class ScholarshipApplication(BaseModel):
    """Student application stored in `scholarship_applications`."""
    id: Optional[str] = Field(default=None, alias="_id")
    scholarship_id: str              # ref → scholarships._id
    student_id: str                  # ref → users._id (student)
    status: ApplicationStatus = ApplicationStatus.draft
    document_ids: List[str] = Field(default_factory=list)  # ref → documents._id
    statement: Optional[str] = None  # personal statement
    applied_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    reviewer_note: Optional[str] = None

    class Config:
        populate_by_name = True
