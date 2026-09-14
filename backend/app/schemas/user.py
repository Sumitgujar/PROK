from pydantic import BaseModel, EmailStr
from typing import Optional
from app.models.user import UserRole


# ---------- Request schemas ----------

class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: UserRole = UserRole.student
    college_id: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


# ---------- Response schemas ----------

class UserOut(BaseModel):
    id: Optional[str] = None
    name: str
    email: str
    role: UserRole
    is_active: bool
    college_id: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut
