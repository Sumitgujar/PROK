from fastapi import APIRouter, Depends, HTTPException

from app.core.dependencies import require_role
from app.models.intelligence import RecoverySimulationRequest
from app.services import intelligence as svc
from app.services.intelligence_rules import build_recovery_projection

router = APIRouter(prefix="/intelligence", tags=["intelligence"])


def _resolve_student_id(current_user: dict, student_id: str | None) -> str:
    if current_user.get("role") == "student":
        return current_user["college_id"]
    if not student_id:
        raise HTTPException(status_code=400, detail="student_id is required for teacher/admin requests")
    return student_id


@router.get("/attendance/risk")
async def attendance_risk(student_id: str | None = None, current_user=Depends(require_role("student", "teacher", "admin"))):
    return await svc.get_attendance_risk(_resolve_student_id(current_user, student_id))


@router.get("/attendance/recovery")
async def attendance_recovery(student_id: str | None = None, current_user=Depends(require_role("student", "teacher", "admin"))):
    return await svc.get_recovery_simulation(_resolve_student_id(current_user, student_id))


@router.post("/attendance/recovery")
async def recovery_from_numbers(data: RecoverySimulationRequest, current_user=Depends(require_role("student", "teacher", "admin"))):
    return build_recovery_projection(data.attended_classes, data.total_classes)


@router.get("/scholarships/matches")
async def scholarship_matches(student_id: str | None = None, current_user=Depends(require_role("student", "teacher", "admin"))):
    return await svc.get_scholarship_intelligence(_resolve_student_id(current_user, student_id))


@router.get("/courses/recommendations")
async def course_recommendations(student_id: str | None = None, current_user=Depends(require_role("student", "teacher", "admin"))):
    return await svc.get_course_recommendations(_resolve_student_id(current_user, student_id))
