from fastapi import APIRouter, Depends
from app.models.course import CourseCreate, ProfileUpdate
from app.services import course as svc
from app.core.dependencies import get_current_user, require_role

router = APIRouter(prefix="/courses", tags=["courses"])

@router.get("/")
async def list_courses(department: str = None, current_user=Depends(get_current_user)):
    return await svc.get_courses(department)

@router.post("/enroll")
async def enroll(body: dict, current_user=Depends(require_role("student"))):
    return await svc.enroll_student(body["course_id"], current_user["college_id"])

@router.get("/my-enrollments")
async def my_enrollments(current_user=Depends(require_role("student"))):
    return await svc.get_student_enrollments(current_user["college_id"])

@router.get("/recommendations")
async def recommendations(current_user=Depends(require_role("student"))):
    return await svc.get_recommendations(current_user["college_id"])

@router.get("/profile")
async def profile(current_user=Depends(require_role("student"))):
    return await svc.get_student_profile(current_user["college_id"])

@router.put("/profile")
async def update_profile(data: ProfileUpdate, current_user=Depends(require_role("student"))):
    return await svc.update_profile(current_user["college_id"], data.skills, data.interests, data.career_goals)

@router.post("/", status_code=201)
async def create_course(data: CourseCreate, current_user=Depends(require_role("admin"))):
    from app.db.connection import get_database
    from datetime import datetime, timezone
    db = get_database()
    result = await db.courses.insert_one({**data.dict(), "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat()})
    return {"id": str(result.inserted_id)}
