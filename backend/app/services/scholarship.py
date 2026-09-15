from app.db.connection import get_database
from fastapi import HTTPException
from bson import ObjectId
from datetime import datetime, timezone

async def get_scholarships():
    db = get_database()
    docs = await db.scholarships.find({"is_active": {"$ne": False}}).to_list(None)
    for d in docs:
        d["_id"] = str(d["_id"])
    return docs

async def apply_scholarship(scholarship_id: str, student_college_id: str, user_id: str):
    db = get_database()
    sch = await db.scholarships.find_one({"_id": ObjectId(scholarship_id)})
    if not sch:
        raise HTTPException(status_code=404, detail="Scholarship not found")
    existing = await db.scholarship_applications.find_one(
        {"scholarship_id": scholarship_id, "student_id": student_college_id})
    if existing:
        raise HTTPException(status_code=409, detail="Already applied")
    # calculate missing docs
    required = set(sch.get("required_doc_types", []))
    verified_docs = await db.documents.find(
        {"student_id": student_college_id, "status": "VERIFIED"}).to_list(None)
    verified_types = {d["doc_type"] for d in verified_docs}
    missing = list(required - verified_types)
    result = await db.scholarship_applications.insert_one({
        "scholarship_id": scholarship_id,
        "scholarship_name": sch["name"],
        "student_id": student_college_id,
        "user_id": user_id,
        "status": "pending",
        "applied_at": datetime.now(timezone.utc).isoformat(),
        "missing_docs": missing,
        "review_note": None,
        "reviewed_at": None,
    })
    return {"id": str(result.inserted_id), "missing_docs": missing}

async def get_student_applications(student_college_id: str):
    db = get_database()
    apps = await db.scholarship_applications.find({"student_id": student_college_id}).to_list(None)
    for a in apps:
        a["_id"] = str(a["_id"])
    return apps

async def review_application(app_id: str, reviewer_id: str, status: str, note: str = None):
    db = get_database()
    if status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="Invalid status")
    app = await db.scholarship_applications.find_one({"_id": ObjectId(app_id)})
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
    await db.scholarship_applications.update_one(
        {"_id": ObjectId(app_id)},
        {"$set": {"status": status, "reviewed_by": reviewer_id, "review_note": note,
                  "reviewed_at": datetime.now(timezone.utc).isoformat()}}
    )
    return {"status": status}

async def get_all_applications():
    db = get_database()
    apps = await db.scholarship_applications.find().sort("applied_at", -1).to_list(None)
    for a in apps:
        a["_id"] = str(a["_id"])
        user = await db.users.find_one({"college_id": a["student_id"]})
        a["student_name"] = user["full_name"] if user else a["student_id"]
    return apps
