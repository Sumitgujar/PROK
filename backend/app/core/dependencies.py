"""
Centralised auth dependencies.
get_current_user and require_role live here to avoid circular imports.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.security import decode_token
from app.db.connection import get_db
from app.models.user import UserRole
from app.schemas.user import UserOut
from app.services import auth_service

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncIOMotorDatabase = Depends(get_db),
) -> UserOut:
    """Decode JWT and return the authenticated user from the database."""
    payload = decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = await auth_service.get_user_by_id(db, payload["sub"])
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )
    return user


def require_role(*roles: UserRole):
    """
    Factory dependency — restricts endpoint to one or more roles.

    Usage:
        @router.get("/admin-only")
        async def endpoint(user: UserOut = Depends(require_role(UserRole.admin))):
            ...
    """
    def _check(current_user: UserOut = Depends(get_current_user)) -> UserOut:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required role(s): {[r.value for r in roles]}",
            )
        return current_user
    # Give the inner function a unique name so FastAPI doesn't collapse dependencies
    _check.__name__ = f"require_{'_or_'.join(r.value for r in roles)}"
    return _check


# Convenience shortcuts
def require_admin(current_user: UserOut = Depends(require_role(UserRole.admin))) -> UserOut:
    return current_user


def require_teacher_or_admin(
    current_user: UserOut = Depends(require_role(UserRole.teacher, UserRole.admin)),
) -> UserOut:
    return current_user


def require_student_or_admin(
    current_user: UserOut = Depends(require_role(UserRole.student, UserRole.admin)),
) -> UserOut:
    return current_user
