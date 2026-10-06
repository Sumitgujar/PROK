from fastapi import APIRouter
router = APIRouter()
@router.get("/")
@router.get("/health")
async def health(): return {"status": "ok", "service": "PROK Backend"}
