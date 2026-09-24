"""
PROK DEMO SEED — Aarav Shah
============================
This script inserts clearly marked DEMO DATA for hackathon demonstrations.
Safe to run multiple times — wipes previous demo data first.

Usage:
    cd backend
    python -m scripts.seed_demo
"""
import asyncio, sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings
from app.core.security import hash_password
from datetime import datetime, timezone, timedelta, date
from bson import ObjectId

DEMO_TAG = "[DEMO]"

def now(): return datetime.now(timezone.utc)
def dstr(d): return d.isoformat()
def past(days): return (now() - timedelta(days=days))

async def seed():
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.MONGO_DB]
    await client.admin.command("ping")
    print(f"Connected to {settings.MONGO_URI}/{settings.MONGO_DB}")

    # ── 1. WIPE previous demo data ────────────────────────────────
    print("\nCleaning previous demo data...")
    await db.users.delete_many({"email": {"$in": ["aarav@prok.edu", "drmeera@prok.edu"]}})
    await db.students.delete_many({"college_id": "STU2024042"})
    await db.teachers.delete_many({"college_id": "EMP2024010"})
    # Clean demo courses
    demo_codes = ["CS301","CS302","CS303","MA201","CS401"]
    await db.courses.delete_many({"course_code": {"$in": demo_codes}})
    await db.scholarships.delete_many({"name": {"$regex": "^\\[DEMO\\]"}})
    await db.interventions.delete_many({"student_id": "STU2024042"})
    await db.notifications.delete_many({"ntype": {"$in": ["demo","attendance","document","scholarship"]}, "title": {"$regex": "DEMO"}})
    print("  Done.")

    # ── 2. TEACHER: Dr. Meera Krishnan ───────────────────────────
    print("\nCreating demo teacher...")
    teacher_user = await db.users.find_one({"email": "teacher@prok.edu"})
    if not teacher_user:
        tr = await db.users.insert_one({
            "full_name": "Dr. Meera Krishnan",
            "email": "drmeera@prok.edu",
            "hashed_password": hash_password("teacher123"),
            "role": "teacher",
            "is_active": True,
            "college_id": "EMP2024010",
            "created_at": now(),
        })
        teacher_id = str(tr.inserted_id)
        teacher_cid = "EMP2024010"
    else:
        teacher_id = str(teacher_user["_id"])
        teacher_cid = teacher_user.get("college_id", "EMP2024001")
    print(f"  Teacher ID: {teacher_id}")

    # ── 3. STUDENT: Aarav Shah ────────────────────────────────────
    print("\nCreating Aarav Shah...")
    stu_res = await db.users.insert_one({
        "full_name": "Aarav Shah",
        "email": "aarav@prok.edu",
        "hashed_password": hash_password("aarav123"),
        "role": "student",
        "is_active": True,
        "college_id": "STU2024042",
        "created_at": now(),
    })
    stu_uid = str(stu_res.inserted_id)
    stu_cid = "STU2024042"
    await db.students.insert_one({
        "college_id": stu_cid,
        "user_id": stu_uid,
        "department": "Computer Science",
        "year": 3,
        "semester": 5,
        "cgpa": 7.4,
        "skills": ["Python", "Machine Learning", "Data Analysis", "SQL", "Flask"],
        "interests": ["Artificial Intelligence", "Data Science", "Cloud Computing"],
        "career_goals": ["Data Scientist", "ML Engineer", "Backend Developer"],
        "skills_description": "Strong Python foundation, working knowledge of scikit-learn and pandas.",
        "address": "Mumbai, Maharashtra",
        "demo": True,
    })
    print(f"  Aarav UID: {stu_uid}, College ID: {stu_cid}")

    # ── 4. COURSES ────────────────────────────────────────────────
    print("\nCreating demo courses...")
    course_defs = [
        {"course_code": "CS301", "title": "Data Structures & Algorithms", "department": "Computer Science", "credits": 4,
         "description": "Trees, graphs, sorting, and dynamic programming.",
         "tags": ["algorithms", "data structures", "python", "problem solving"],
         "enrolled_count": 45},
        {"course_code": "CS302", "title": "Database Management Systems", "department": "Computer Science", "credits": 3,
         "description": "Relational databases, SQL, normalization, transactions.",
         "tags": ["SQL", "databases", "data engineering"],
         "enrolled_count": 40},
        {"course_code": "CS303", "title": "Machine Learning Fundamentals", "department": "Computer Science", "credits": 4,
         "description": "Supervised and unsupervised learning, model evaluation, scikit-learn.",
         "tags": ["machine learning", "python", "data science", "AI"],
         "enrolled_count": 38},
        {"course_code": "MA201", "title": "Probability & Statistics", "department": "Mathematics", "credits": 3,
         "description": "Probability theory, distributions, hypothesis testing, regression.",
         "tags": ["statistics", "data science", "mathematics"],
         "enrolled_count": 60},
        {"course_code": "CS401", "title": "Cloud Computing & DevOps", "department": "Computer Science", "credits": 3,
         "description": "AWS, Docker, CI/CD, microservices architecture.",
         "tags": ["cloud", "devops", "AWS", "backend"],
         "enrolled_count": 30},
    ]
    course_ids = {}
    for cd in course_defs:
        res = await db.courses.insert_one({
            **cd,
            "teacher_id": teacher_id,
            "teacher_college_id": teacher_cid,
            "is_active": True,
            "created_at": now(),
        })
        course_ids[cd["course_code"]] = str(res.inserted_id)
        print(f"  Course {cd['course_code']}: {res.inserted_id}")

    # ── 5. ENROLL Aarav in all 5 courses ─────────────────────────
    print("\nEnrolling Aarav...")
    for code, cid in course_ids.items():
        await db.enrollments.insert_one({
            "student_college_id": stu_cid,
            "course_id": cid,
            "course_code": code,
            "status": "active",
            "enrolled_at": dstr(past(90)),
        })
    print("  Enrolled in 5 courses")

    # ── 6. ATTENDANCE SESSIONS + RECORDS ─────────────────────────
    # Pattern for each course: 20 sessions over 10 weeks
    # Aarav is at risk in CS301 (62%) and MA201 (58%) due to recent absences
    print("\nCreating attendance sessions...")

    attendance_patterns = {
        "CS301": ["present","present","absent","present","present","absent","present","absent",
                  "present","absent","absent","present","absent","absent","present","absent",
                  "absent","present","absent","absent"],  # 8/20 = 40% — HIGH RISK
        "CS302": ["present","present","present","present","late","present","present","present",
                  "absent","present","present","present","present","late","present","present",
                  "present","present","present","present"],  # 18/20 = 90% — LOW
        "CS303": ["present","absent","present","present","present","present","absent","present",
                  "present","present","present","present","absent","present","present","present",
                  "present","present","present","present"],  # 17/20 = 85% — LOW
        "MA201": ["absent","present","absent","present","absent","absent","present","absent",
                  "present","absent","absent","present","absent","absent","present","absent",
                  "absent","absent","present","absent"],  # 7/20 = 35% — HIGH RISK
        "CS401": ["present","present","present","late","present","present","present","present",
                  "absent","present","present","present","present","present","present","present",
                  "present","present","present","present"],  # 19/20 = 95% — LOW
    }

    for code, statuses in attendance_patterns.items():
        cid = course_ids[code]
        for i, status in enumerate(statuses):
            # Sessions spread over 70 days, 2 per week roughly
            session_date = (now() - timedelta(days=70 - i * 3)).date().isoformat()
            sess_res = await db.attendance_sessions.insert_one({
                "course_id": cid,
                "course_code": code,
                "course_title": next(c["title"] for c in course_defs if c["course_code"] == code),
                "teacher_id": teacher_id,
                "date": session_date,
                "present": 1 if status in ("present", "late") else 0,
                "absent": 1 if status == "absent" else 0,
                "total": 1,
                "created_at": now(),
            })
            await db.attendance_records.insert_one({
                "session_id": str(sess_res.inserted_id),
                "student_id": stu_cid,
                "status": status,
                "marked_at": dstr(now()),
                "marked_by": teacher_id,
            })
    print("  100 attendance records created (5 courses x 20 sessions)")

    # ── 7. DOCUMENTS ─────────────────────────────────────────────
    print("\nCreating documents...")
    docs = [
        {"doc_type": "income_certificate", "title": "[DEMO] Family Income Certificate",
         "status": "VERIFIED", "uploaded_at": dstr(past(45))},
        {"doc_type": "marksheet", "title": "[DEMO] Semester 4 Marksheet",
         "status": "VERIFIED", "uploaded_at": dstr(past(30))},
        {"doc_type": "bonafide", "title": "[DEMO] Bonafide Certificate",
         "status": "UNDER_REVIEW", "uploaded_at": dstr(past(5))},
        {"doc_type": "caste_certificate", "title": "[DEMO] Caste Certificate",
         "status": "REJECTED", "review_note": "Document unclear, please re-upload a higher quality scan.",
         "uploaded_at": dstr(past(20))},
    ]
    for doc in docs:
        await db.documents.insert_one({
            "student_id": stu_cid,
            "description": "",
            "file_url": "/files/demo/placeholder.pdf",
            "file_size": 204800,
            "original_filename": f"{doc['doc_type']}_demo.pdf",
            "reviewed_at": dstr(past(3)) if doc["status"] != "UNDER_REVIEW" else None,
            "reviewed_by": None,
            "review_note": doc.get("review_note"),
            **doc,
        })
    print("  4 documents created")

    # ── 8. SCHOLARSHIPS ──────────────────────────────────────────
    print("\nCreating scholarships...")
    scholarships = [
        {"name": "[DEMO] National Merit Scholarship",
         "provider": "Ministry of Education",
         "amount": 50000, "currency": "INR",
         "description": "For students with CGPA above 7.0 and family income below 5 LPA.",
         "required_doc_types": ["income_certificate", "marksheet"],
         "min_cgpa": 7.0,
         "eligible_departments": ["Computer Science", "Electronics", "Mechanical"],
         "deadline": (now() + timedelta(days=30)).date().isoformat(),
         "tags": ["merit", "national"],
         "is_active": True},
        {"name": "[DEMO] SC/ST Excellence Award",
         "provider": "State Government",
         "amount": 30000, "currency": "INR",
         "description": "For SC/ST students in technical courses with CGPA above 6.5.",
         "required_doc_types": ["caste_certificate", "bonafide", "marksheet"],
         "min_cgpa": 6.5,
         "eligible_departments": ["Computer Science", "Electronics"],
         "deadline": (now() + timedelta(days=15)).date().isoformat(),
         "tags": ["sc-st", "state"],
         "is_active": True},
        {"name": "[DEMO] Tech Innovation Grant",
         "provider": "PROK Institute",
         "amount": 25000, "currency": "INR",
         "description": "For CS students interested in AI/ML with strong academic record.",
         "required_doc_types": ["bonafide", "marksheet"],
         "min_cgpa": 7.0,
         "eligible_departments": ["Computer Science"],
         "deadline": (now() + timedelta(days=45)).date().isoformat(),
         "tags": ["AI", "ML", "innovation"],
         "is_active": True},
    ]
    for s in scholarships:
        await db.scholarships.insert_one({**s, "created_at": now()})
    print("  3 scholarships created")

    # ── 9. INTERVENTION ──────────────────────────────────────────
    print("\nCreating intervention record...")
    await db.interventions.insert_one({
        "student_id": stu_cid,
        "student_name": "Aarav Shah",
        "reason": "Attendance in CS301 (Data Structures) and MA201 (Probability & Statistics) has dropped below 60%. Risk level: HIGH. 5 consecutive absences in MA201.",
        "status": "OPEN",
        "priority": "HIGH",
        "type": "attendance",
        "assigned_to": teacher_cid,
        "note": "[DEMO] Student reached out informally. Suggested attending extra sessions.",
        "created_at": dstr(past(7)),
        "updated_at": dstr(past(7)),
        "demo": True,
    })
    print("  Intervention created")

    # ── 10. NOTIFICATIONS for Aarav ──────────────────────────────
    print("\nCreating notifications...")
    notifs = [
        {"title": "[DEMO] Attendance Warning: CS301",
         "message": "Your attendance in Data Structures & Algorithms has dropped to 40%. You need at least 75% to appear for exams. Please attend all upcoming sessions.",
         "ntype": "attendance", "is_read": False, "created_at": dstr(past(2))},
        {"title": "[DEMO] Attendance Critical: MA201",
         "message": "CRITICAL: Your attendance in Probability & Statistics is 35%. You have 5 consecutive absences. Your teacher has been notified.",
         "ntype": "attendance", "is_read": False, "created_at": dstr(past(1))},
        {"title": "[DEMO] Document Rejected: Caste Certificate",
         "message": "Your Caste Certificate was rejected. Reason: Document unclear, please re-upload a higher quality scan.",
         "ntype": "document", "is_read": True, "created_at": dstr(past(18))},
        {"title": "[DEMO] Document Verified: Income Certificate",
         "message": "Your Family Income Certificate has been verified. You are now eligible for income-based scholarships.",
         "ntype": "document", "is_read": True, "created_at": dstr(past(43))},
        {"title": "[DEMO] Scholarship Deadline: Tech Innovation Grant",
         "message": "The Tech Innovation Grant deadline is in 45 days. You appear eligible — check your scholarship tab and apply.",
         "ntype": "scholarship", "is_read": False, "created_at": dstr(past(3))},
    ]
    for n in notifs:
        await db.notifications.insert_one({"recipient_id": stu_uid, **n})
    print(f"  {len(notifs)} notifications created")

    # ── 11. SUMMARY ──────────────────────────────────────────────
    print("\n" + "="*50)
    print("DEMO SEED COMPLETE")
    print("="*50)
    print(f"  Student:   Aarav Shah <aarav@prok.edu> / aarav123")
    print(f"  College ID: {stu_cid}")
    print(f"  Courses:   CS301 (40%) | CS302 (90%) | CS303 (85%) | MA201 (35%) | CS401 (95%)")
    print(f"  Risk:      HIGH — CS301 and MA201 below threshold")
    print(f"  Documents: 2 Verified | 1 Under Review | 1 Rejected")
    print(f"  Schols:    3 active scholarships")
    print(f"  Notifs:    5 (2 unread attendance, 1 unread scholarship)")
    print(f"  Intervention: OPEN (attendance)")
    print("")
    print("  Existing accounts (unchanged):")
    print("  Student:  student@prok.edu / student123")
    print("  Teacher:  teacher@prok.edu / teacher123")
    print("  Admin:    admin@prok.edu   / admin123")
    client.close()

if __name__ == "__main__" or __name__ == "scripts.seed_demo":
    asyncio.run(seed())
