from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class MessageRole(str, Enum):
    user = "user"
    assistant = "assistant"
    system = "system"


class ChatMessage(BaseModel):
    role: MessageRole
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class AiConversation(BaseModel):
    """AI Guide conversation stored in `ai_conversations`."""
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str                     # ref → users._id
    title: Optional[str] = None      # auto-generated from first message
    messages: List[ChatMessage] = Field(default_factory=list)
    model_used: Optional[str] = None  # e.g. "gpt-4o-mini"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
