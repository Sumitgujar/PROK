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

from pydantic import BaseModel, EmailStr
from typing import Optional, List
from fastapi import HTTPException
from bson import ObjectId

class StudentCreateRequest(BaseModel):
    full_name: str
    email: EmailStr
    college_id: str
    password: Optional[str] = "student123"
    department: Optional[str] = "Computer Science"
    semester: Optional[int] = 1
    year: Optional[int] = 1
    cgpa: Optional[float] = 0.0
    skills: Optional[List[str]] = []
    interests: Optional[List[str]] = []
    career_goals: Optional[List[str]] = []

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

@router.post("/students", status_code=201)
async def create_student(data: StudentCreateRequest, current_user=Depends(require_role("admin"))):
    db = get_database()
    email_clean = data.email.strip().lower()
    cid_clean = data.college_id.strip()

    if await db.users.find_one({"email": email_clean}):
        raise HTTPException(status_code=400, detail="Student email is already registered")
    if await db.users.find_one({"college_id": cid_clean}):
        raise HTTPException(status_code=400, detail="College ID is already assigned to an existing user")

    from app.core.security import hash_password
    from datetime import datetime, timezone

    user_doc = {
        "name": data.full_name.strip(),
        "full_name": data.full_name.strip(),
        "email": email_clean,
        "hashed_password": hash_password(data.password or "student123"),
        "role": "student",
        "college_id": cid_clean,
        "is_active": True,
        "created_at": datetime.now(timezone.utc),
    }
    user_res = await db.users.insert_one(user_doc)

    student_doc = {
        "user_id": str(user_res.inserted_id),
        "college_id": cid_clean,
        "department": data.department or "Computer Science",
        "semester": data.semester or 1,
        "year": data.year or 1,
        "cgpa": float(data.cgpa or 0.0),
        "skills": data.skills or [],
        "interests": data.interests or [],
        "career_goals": data.career_goals or [],
    }
    await db.students.insert_one(student_doc)
    return {"id": str(user_res.inserted_id), "message": "Student created successfully"}

@router.delete("/students/{user_id}")
async def delete_student(user_id: str, current_user=Depends(require_role("admin"))):
    db = get_database()
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=404, detail="Student not found")
    cid = user.get("college_id")
    await db.users.delete_one({"_id": ObjectId(user_id)})
    if cid:
        await db.students.delete_many({"college_id": cid})
        await db.enrollments.delete_many({"student_college_id": cid})
    return {"message": "Student deleted"}

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
