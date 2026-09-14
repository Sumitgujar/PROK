from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class AdminProfile(BaseModel):
    """Extended profile stored in the `admins` collection."""
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str                     # ref → users._id
    employee_id: str
    department: str = "Administration"
    permissions: List[str] = Field(
        default_factory=lambda: ["all"]
    )                                # e.g. ["all"] or ["analytics", "verification"]
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
