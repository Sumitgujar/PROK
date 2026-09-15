from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.connection import get_db
from app.schemas.user import UserRegister, TokenResponse, UserOut
from app.services import auth_service
from app.core.dependencies import get_current_user  # centralised dependency

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(data: UserRegister, db: AsyncIOMotorDatabase = Depends(get_db)):
    """
    Register a new user. Role is always set to 'student' by the backend.
    The client cannot choose its own role.
    """
    try:
        return await auth_service.register_user(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
async def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """OAuth2 password flow. username field must contain the user's email."""
    try:
        return await auth_service.login_user(db, form.username, form.password)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.get("/me", response_model=UserOut)
async def me(current_user: UserOut = Depends(get_current_user)):
    """Return the currently authenticated user's profile."""
    return current_user
