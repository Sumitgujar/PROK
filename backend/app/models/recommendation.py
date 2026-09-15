from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime
from enum import Enum


class RecommendationType(str, Enum):
    course = "course"
    scholarship = "scholarship"
    resource = "resource"


class RecommendationItem(BaseModel):
    item_id: str                     # ref → courses._id or scholarships._id
    title: str
    score: float = 1.0               # relevance score 0-1
    reason: Optional[str] = None


class Recommendation(BaseModel):
    """AI-generated recommendations stored in `recommendations`."""
    id: Optional[str] = Field(default=None, alias="_id")
    student_id: str                  # ref → users._id (student)
    rec_type: RecommendationType
    items: List[RecommendationItem] = Field(default_factory=list)
    model_version: Optional[str] = None
    generated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
