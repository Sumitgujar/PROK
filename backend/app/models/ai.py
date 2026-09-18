from pydantic import BaseModel, Field


class AiChatRequest(BaseModel):
    question: str = Field(min_length=2, max_length=500)


class AiChatResponse(BaseModel):
    answer: str
    intent: str
    actions: list[dict] = []
    warnings: list[str] = []
