"""
Demo endpoints that showcase role-based access control.
Useful for manual testing with the seed accounts.
"""
from fastapi import APIRouter, Depends
from app.schemas.user import UserOut
from app.core.dependencies import (
    get_current_user,
    require_role,
    require_admin,
    require_teacher_or_admin,
    require_student_or_admin,
)
from app.models.user import UserRole

router = APIRouter(prefix="/demo", tags=["Demo / RBAC"])


@router.get("/whoami")
async def whoami(user: UserOut = Depends(get_current_user)):
    """Any authenticated user."""
    return {"id": user.id, "name": user.name, "role": user.role}


@router.get("/student-area")
async def student_area(
    user: UserOut = Depends(require_role(UserRole.student, UserRole.admin)),
):
    """Students and admins only."""
    return {"message": f"Welcome to the student area, {user.name}"}


@router.get("/teacher-area")
async def teacher_area(user: UserOut = Depends(require_teacher_or_admin)):
    """Teachers and admins only."""
    return {"message": f"Welcome to the teacher area, {user.name}"}


@router.get("/admin-area")
async def admin_area(user: UserOut = Depends(require_admin)):
    """Admins only."""
    return {"message": f"Welcome to the admin area, {user.name}"}
