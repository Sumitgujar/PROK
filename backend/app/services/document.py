from app.db.connection import get_database
from fastapi import UploadFile, HTTPException
from app.services.storage import save_file
from bson import ObjectId
from datetime import datetime, timezone

async def upload_document(file: UploadFile, student_id: str, doc_type: str, title: str, description: str = ""):
    db = get_database()
    file_url, file_size, filename = await save_file(file, student_id)
    result = await db.documents.insert_one({
        "student_id": student_id,
        "doc_type": doc_type,
        "title": title,
        "description": description,
        "file_url": file_url,
        "file_size": file_size,
        "original_filename": filename,
        "status": "UNDER_REVIEW",
        "uploaded_at": datetime.now(timezone.utc).isoformat(),
        "reviewed_at": None,
        "reviewed_by": None,
        "review_note": None,
    })
    return {"id": str(result.inserted_id), "status": "UNDER_REVIEW"}

async def get_student_documents(student_id: str):
    db = get_database()
    docs = await db.documents.find({"student_id": student_id}).sort("uploaded_at", -1).to_list(None)
    for d in docs:
        d["_id"] = str(d["_id"])
    return docs

async def review_document(doc_id: str, reviewer_id: str, status: str, note: str = None):
    db = get_database()
    if status not in ("VERIFIED", "REJECTED"):
        raise HTTPException(status_code=400, detail="Invalid status")
    doc = await db.documents.find_one({"_id": ObjectId(doc_id)})
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    await db.documents.update_one(
        {"_id": ObjectId(doc_id)},
        {"$set": {"status": status, "reviewed_by": reviewer_id, "review_note": note,
                  "reviewed_at": datetime.now(timezone.utc).isoformat()}}
    )
    return {"status": status}

async def get_all_documents():
    db = get_database()
    docs = await db.documents.find().sort("uploaded_at", -1).to_list(None)
    for d in docs:
        d["_id"] = str(d["_id"])
        user = await db.users.find_one({"college_id": d["student_id"]})
        d["student_name"] = user["full_name"] if user else d["student_id"]
    return docs
