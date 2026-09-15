from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class NotificationType(str, Enum):
    info = "info"
    warning = "warning"
    alert = "alert"
    success = "success"


class Notification(BaseModel):
    """In-app notification stored in `notifications`."""
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str                     # ref → users._id (recipient)
    title: str
    message: str
    notif_type: NotificationType = NotificationType.info
    is_read: bool = False
    action_url: Optional[str] = None  # deep-link inside the app
    created_at: datetime = Field(default_factory=datetime.utcnow)
    read_at: Optional[datetime] = None

    class Config:
        populate_by_name = True
