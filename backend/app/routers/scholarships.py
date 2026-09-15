from fastapi import APIRouter, Depends
from app.models.scholarship import ScholarshipCreate, ApplicationReview
from app.services import scholarship as svc
from app.core.dependencies import get_current_user, require_role

router = APIRouter(prefix="/scholarships", tags=["scholarships"])

@router.get("/")
async def list_scholarships(current_user=Depends(get_current_user)):
    return await svc.get_scholarships()

@router.post("/apply")
async def apply(body: dict, current_user=Depends(require_role("student"))):
    return await svc.apply_scholarship(
        body["scholarship_id"], current_user["college_id"], str(current_user["_id"]))

@router.get("/my-applications")
async def my_apps(current_user=Depends(require_role("student"))):
    return await svc.get_student_applications(current_user["college_id"])

@router.get("/applications")
async def all_apps(current_user=Depends(require_role("admin"))):
    return await svc.get_all_applications()

@router.post("/applications/{app_id}/review")
async def review(app_id: str, body: ApplicationReview, current_user=Depends(require_role("admin"))):
    return await svc.review_application(app_id, str(current_user["_id"]), body.status, body.review_note)

@router.post("/", status_code=201)
async def create(data: ScholarshipCreate, current_user=Depends(require_role("admin"))):
    db_func = svc.get_scholarships  # placeholder
    from app.db.connection import get_database
    from datetime import datetime, timezone
    db = get_database()
    result = await db.scholarships.insert_one({**data.dict(), "is_active": True,
        "created_at": datetime.now(timezone.utc).isoformat()})
    return {"id": str(result.inserted_id)}
