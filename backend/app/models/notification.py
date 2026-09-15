from pydantic import BaseModel
from typing import Optional

class NotificationCreate(BaseModel):
    recipient_id: str
    title: str
    message: str
    ntype: str = "general"
    link: Optional[str] = None
