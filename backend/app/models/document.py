from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class DocumentType(str, Enum):
    transcript = "transcript"
    certificate = "certificate"
    id_card = "id_card"
    marksheet = "marksheet"
    fee_receipt = "fee_receipt"
    other = "other"


class Document(BaseModel):
    """Academic document stored in the `documents` collection."""
    id: Optional[str] = Field(default=None, alias="_id")
    owner_id: str                    # ref → users._id
    title: str
    doc_type: DocumentType = DocumentType.other
    file_url: str                    # storage URL / path
    file_size_bytes: Optional[int] = None
    mime_type: Optional[str] = None  # e.g. application/pdf
    tags: List[str] = Field(default_factory=list)
    is_verified: bool = False        # admin verification flag
    uploaded_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
