from fastapi import APIRouter, Depends
from app.services import notification as svc
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("/")
async def get_notifications(current_user=Depends(get_current_user)):
    return await svc.get_notifications(str(current_user["_id"]))

@router.post("/{notification_id}/read")
async def mark_read(notification_id: str, current_user=Depends(get_current_user)):
    return await svc.mark_read(notification_id, str(current_user["_id"]))

@router.post("/mark-all-read")
async def mark_all_read(current_user=Depends(get_current_user)):
    return await svc.mark_all_read(str(current_user["_id"]))
