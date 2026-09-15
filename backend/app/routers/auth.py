from fastapi import APIRouter, Depends
from app.models.user import UserLogin, UserCreate
from app.services.auth import authenticate_user, register_user
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/login")
async def login(data: UserLogin):
    return await authenticate_user(data.email, data.password)

@router.post("/register", status_code=201)
async def register(data: UserCreate):
    return await register_user(data.dict())

@router.get("/me")
async def me(current_user=Depends(get_current_user)):
    u = dict(current_user)
    u["_id"] = str(u["_id"])
    u.pop("hashed_password", None)
    return u
