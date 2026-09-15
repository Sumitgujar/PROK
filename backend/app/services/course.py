from app.db.connection import get_database
from fastapi import HTTPException
from bson import ObjectId
from datetime import datetime, timezone

async def get_courses(department: str = None):
    db = get_database()
    q = {"is_active": {"$ne": False}}
    if department:
        q["department"] = department
    docs = await db.courses.find(q).to_list(None)
    for d in docs:
        d["_id"] = str(d["_id"])
        count = await db.enrollments.count_documents({"course_id": str(d["_id"])})
        d["enrolled_count"] = count
        teacher = await db.users.find_one({"college_id": d.get("teacher_college_id","")})
        d["teacher_name"] = teacher["full_name"] if teacher else "TBA"
    return docs

async def enroll_student(course_id: str, student_college_id: str):
    db = get_database()
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    existing = await db.enrollments.find_one({"course_id": course_id, "student_college_id": student_college_id})
    if existing:
        raise HTTPException(status_code=409, detail="Already enrolled")
    result = await db.enrollments.insert_one({
        "course_id": course_id,
        "course_code": course.get("course_code"),
        "course_title": course.get("title"),
        "student_college_id": student_college_id,
        "status": "active",
        "enrolled_at": datetime.now(timezone.utc).isoformat(),
    })
    return {"id": str(result.inserted_id)}

async def get_student_enrollments(student_college_id: str):
    db = get_database()
    enrs = await db.enrollments.find({"student_college_id": student_college_id}).to_list(None)
    for e in enrs:
        e["_id"] = str(e["_id"])
    return enrs

async def get_recommendations(student_college_id: str):
    db = get_database()
    student = await db.students.find_one({"college_id": student_college_id})
    dept = student.get("department") if student else None
    enrolled_ids = {e["course_id"] for e in await db.enrollments.find({"student_college_id": student_college_id}).to_list(None)}
    q = {"is_active": {"$ne": False}}
    if dept:
        q["department"] = dept
    courses = await db.courses.find(q).to_list(None)
    recs = []
    for c in courses:
        cid = str(c["_id"])
        if cid not in enrolled_ids:
            c["_id"] = cid
            recs.append(c)
        if len(recs) >= 5:
            break
    return recs

async def update_profile(student_college_id: str, skills: list, interests: list, career_goals: list):
    db = get_database()
    await db.students.update_one(
        {"college_id": student_college_id},
        {"$set": {"skills": skills, "interests": interests, "career_goals": career_goals}},
        upsert=True
    )
    return {"updated": True}

async def get_student_profile(student_college_id: str):
    db = get_database()
    p = await db.students.find_one({"college_id": student_college_id})
    if p:
        p["_id"] = str(p["_id"])
    return p
