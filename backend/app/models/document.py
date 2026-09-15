from pydantic import BaseModel
from typing import Optional

class DocumentReview(BaseModel):
    review_note: Optional[str] = None

class DocumentStatus:
    UNDER_REVIEW = "UNDER_REVIEW"
    VERIFIED = "VERIFIED"
    REJECTED = "REJECTED"
