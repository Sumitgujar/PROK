from fastapi import APIRouter, Depends
from app.models.attendance import MarkAttendanceRequest
from app.services import attendance as svc
from app.core.dependencies import get_current_user, require_role

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.post("/mark")
async def mark(data: MarkAttendanceRequest, current_user=Depends(require_role("teacher"))):
    return await svc.mark_attendance(
        data.course_id, [r.dict() for r in data.records],
        str(current_user["_id"]), data.date, data.notes or "")

@router.get("/student/summary")
async def student_summary(current_user=Depends(require_role("student"))):
    return await svc.get_student_summary(current_user["college_id"])

@router.get("/teacher/courses")
async def teacher_courses(current_user=Depends(require_role("teacher"))):
    return await svc.get_teacher_courses(str(current_user["_id"]))

@router.get("/courses/{course_id}/students")
async def enrolled_students(course_id: str, current_user=Depends(require_role("teacher"))):
    return await svc.get_enrolled_students(course_id)

@router.get("/courses/{course_id}/history")
async def course_history(course_id: str, current_user=Depends(require_role("teacher","admin"))):
    return await svc.get_course_history(course_id)

@router.get("/sessions/today")
async def today_sessions(current_user=Depends(require_role("admin"))):
    return await svc.get_today_sessions()

@router.get("/sessions/{session_id}/records")
async def session_records(session_id: str, current_user=Depends(require_role("admin","teacher"))):
    return await svc.get_session_records(session_id)
