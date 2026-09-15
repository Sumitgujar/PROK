from pydantic import BaseModel, EmailStr
from typing import Optional
from app.models.user import UserRole


# ---------- Request schemas ----------

class UserRegister(BaseModel):
    """
    Public registration schema.
    `role` is intentionally absent — the backend always assigns 'student'.
    Never trust the client to declare its own role.
    """
    name: str
    email: EmailStr
    password: str
    college_id: Optional[str] = None


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
