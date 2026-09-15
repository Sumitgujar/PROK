from pydantic import BaseModel
from typing import List, Optional

class ScholarshipCreate(BaseModel):
    name: str
    provider: str
    amount: float
    currency: str = "USD"
    description: str
    eligibility: str = ""
    required_doc_types: List[str] = []
    deadline: Optional[str] = None
    min_cgpa: Optional[float] = None

class ScholarshipApply(BaseModel):
    scholarship_id: str

class ApplicationReview(BaseModel):
    status: str  # approved, rejected
    review_note: Optional[str] = None
