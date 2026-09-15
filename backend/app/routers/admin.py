from fastapi import APIRouter, Depends
from app.core.dependencies import require_role
from app.db.connection import get_database

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/stats")
async def stats(current_user=Depends(require_role("admin"))):
    db = get_database()
    return {
        "total_students": await db.students.count_documents({}),
        "total_courses": await db.courses.count_documents({}),
        "total_documents": await db.documents.count_documents({}),
        "pending_documents": await db.documents.count_documents({"status": "UNDER_REVIEW"}),
        "total_scholarships": await db.scholarships.count_documents({}),
        "pending_scholarship_applications": await db.scholarship_applications.count_documents({"status": "pending"}),
    }

@router.get("/students")
async def students(current_user=Depends(require_role("admin"))):
    db = get_database()
    users = await db.users.find({"role": "student"}).to_list(None)
    result = []
    for u in users:
        u["_id"] = str(u["_id"])
        u.pop("hashed_password", None)
        s = await db.students.find_one({"college_id": u["college_id"]})
        if s:
            u["department"] = s.get("department")
            u["semester"] = s.get("semester")
            u["cgpa"] = s.get("cgpa")
        result.append(u)
    return result

@router.get("/documents")
async def documents(current_user=Depends(require_role("admin"))):
    from app.services import document as doc_svc
    return await doc_svc.get_all_documents()

@router.post("/documents/{doc_id}/verify")
async def verify_doc(doc_id: str, body: dict = {}, current_user=Depends(require_role("admin"))):
    from app.services import document as doc_svc
    return await doc_svc.review_document(doc_id, str(current_user["_id"]), "VERIFIED", body.get("review_note"))

@router.post("/documents/{doc_id}/reject")
async def reject_doc(doc_id: str, body: dict = {}, current_user=Depends(require_role("admin"))):
    from app.services import document as doc_svc
    return await doc_svc.review_document(doc_id, str(current_user["_id"]), "REJECTED", body.get("review_note"))

@router.get("/scholarship-applications")
async def scholarship_apps(current_user=Depends(require_role("admin"))):
    from app.services import scholarship as sch_svc
    return await sch_svc.get_all_applications()

@router.post("/scholarship-applications/{app_id}/review")
async def review_app(app_id: str, body: dict, current_user=Depends(require_role("admin"))):
    from app.services import scholarship as sch_svc
    return await sch_svc.review_application(app_id, str(current_user["_id"]), body["status"], body.get("review_note"))
