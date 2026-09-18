from fastapi import APIRouter, Depends

from app.core.dependencies import require_role
from app.models.ai import AiChatRequest
from app.services.ask_prok import AskProkService

router = APIRouter(prefix="/ai", tags=["ai"])
service = AskProkService()


@router.post("/chat")
async def ai_chat(data: AiChatRequest, current_user=Depends(require_role("student"))):
    return await service.answer_question(question=data.question, user=current_user)
