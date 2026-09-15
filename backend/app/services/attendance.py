from app.db.connection import get_database
from fastapi import HTTPException
from bson import ObjectId
from datetime import datetime, timezone, date

async def mark_attendance(course_id: str, records: list, teacher_id: str, date_str: str = None, notes: str = ""):
    db = get_database()
    course = await db.courses.find_one({"_id": ObjectId(course_id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    teacher = await db.users.find_one({"_id": ObjectId(teacher_id)})
    teacher_college_id = teacher.get("college_id") if teacher else None
    if course.get("teacher_college_id") and course["teacher_college_id"] != teacher_college_id:
        if course.get("teacher_id") != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized for this course")
    today = date_str or date.today().isoformat()
    session = await db.attendance_sessions.find_one({"course_id": course_id, "date": today})
    if not session:
        res = await db.attendance_sessions.insert_one({
            "course_id": course_id,
            "course_code": course.get("course_code"),
            "course_title": course.get("title"),
            "teacher_id": teacher_id,
            "date": today,
            "notes": notes,
            "created_at": datetime.now(timezone.utc),
        })
        session_id = str(res.inserted_id)
    else:
        session_id = str(session["_id"])
    saved = 0
    for r in records:
        sid = r["student_id"]
        status = r["status"]
        if status not in ("present", "absent", "late"):
            continue
        await db.attendance_records.update_one(
            {"session_id": session_id, "student_id": sid},
            {"$set": {"status": status, "marked_at": datetime.now(timezone.utc).isoformat(),
                      "marked_by": teacher_id}},
            upsert=True
        )
        saved += 1
    await db.attendance_sessions.update_one(
        {"_id": ObjectId(session_id)},
        {"$set": {"present": sum(1 for r in records if r["status"]=="present"),
                  "absent": sum(1 for r in records if r["status"]=="absent"),
                  "total": len(records)}}
    )
    return {"session_id": session_id, "saved": saved, "date": today}

async def get_student_summary(student_college_id: str):
    db = get_database()
    enrollments = await db.enrollments.find({"student_college_id": student_college_id}).to_list(None)
    summary = []
    for enr in enrollments:
        course_id = enr["course_id"]
        course = await db.courses.find_one({"_id": ObjectId(course_id)})
        if not course:
            continue
        sessions = await db.attendance_sessions.find({"course_id": course_id}).to_list(None)
        total = len(sessions)
        if total == 0:
            summary.append({"course_id": course_id, "course_code": course.get("course_code",""),
                "course_title": course.get("title",""), "total_sessions": 0,
                "present": 0, "percentage": 0})
            continue
        present = 0
        for s in sessions:
            rec = await db.attendance_records.find_one(
                {"session_id": str(s["_id"]), "student_id": student_college_id,
                 "status": "present"})
            if rec:
                present += 1
        pct = round(present * 100 / total) if total > 0 else 0
        summary.append({"course_id": course_id, "course_code": course.get("course_code",""),
            "course_title": course.get("title",""), "total_sessions": total,
            "present": present, "percentage": pct})
    return summary

async def get_teacher_courses(teacher_id: str):
    db = get_database()
    courses = await db.courses.find({"teacher_id": teacher_id, "is_active": True}).to_list(None)
    result = []
    for c in courses:
        c["_id"] = str(c["_id"])
        count = await db.enrollments.count_documents({"course_id": str(c["_id"])})
        c["enrolled_count"] = count
        result.append(c)
    return result

async def get_course_history(course_id: str):
    db = get_database()
    sessions = await db.attendance_sessions.find({"course_id": course_id}).sort("date", -1).to_list(None)
    result = []
    for s in sessions:
        s["_id"] = str(s["_id"])
        records = await db.attendance_records.find({"session_id": s["_id"]}).to_list(None)
        for rec in records:
            rec["_id"] = str(rec["_id"])
            user = await db.users.find_one({"college_id": rec["student_id"]})
            rec["student_name"] = user["full_name"] if user else rec["student_id"]
        s["records"] = records
        result.append(s)
    return result

async def get_enrolled_students(course_id: str):
    db = get_database()
    enrollments = await db.enrollments.find({"course_id": course_id}).to_list(None)
    students = []
    for enr in enrollments:
        user = await db.users.find_one({"college_id": enr["student_college_id"]})
        if user:
            students.append({"student_id": enr["student_college_id"],
                "full_name": user.get("full_name",""),
                "email": user.get("email",""),
                "college_id": user.get("college_id","")})
    return students

async def get_today_sessions():
    db = get_database()
    from datetime import date
    today = date.today().isoformat()
    sessions = await db.attendance_sessions.find({"date": today}).to_list(None)
    for s in sessions:
        s["_id"] = str(s["_id"])
    return sessions

async def get_session_records(session_id: str):
    db = get_database()
    records = await db.attendance_records.find({"session_id": session_id}).to_list(None)
    for r in records:
        r["_id"] = str(r["_id"])
        user = await db.users.find_one({"college_id": r["student_id"]})
        r["student_name"] = user["full_name"] if user else r["student_id"]
    return records
