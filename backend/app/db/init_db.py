from app.db.connection import get_database
from app.core.security import hash_password
from datetime import datetime, timezone

COLLECTIONS = ["users","students","teachers","admins","courses","enrollments",
    "attendance_sessions","attendance_records","documents","scholarships",
    "scholarship_applications","recommendations","interventions","notifications","ai_conversations"]

DEMO_USERS = [
    {"email":"student@prok.edu","password":"student123","role":"student",
     "full_name":"Alex Johnson","college_id":"STU2024001"},
    {"email":"teacher@prok.edu","password":"teacher123","role":"teacher",
     "full_name":"Dr. Sarah Williams","college_id":"EMP2024001"},
    {"email":"admin@prok.edu","password":"admin123","role":"admin",
     "full_name":"Admin User","college_id":"ADM2024001"},
]

async def init_db():
    db = get_database()
    for col in COLLECTIONS:
        if col not in await db.list_collection_names():
            await db.create_collection(col)
    await db.users.create_index("email", unique=True)
    await db.users.create_index("college_id", unique=True)
    await db.attendance_records.create_index(["session_id","student_id"], unique=True)
    for u in DEMO_USERS:
        if not await db.users.find_one({"email": u["email"]}):
            result = await db.users.insert_one({
                "email": u["email"],
                "hashed_password": hash_password(u["password"]),
                "role": u["role"],
                "full_name": u["full_name"],
                "college_id": u["college_id"],
                "is_active": True,
                "created_at": datetime.now(timezone.utc),
            })
            if u["role"] == "student":
                await db.students.insert_one({
                    "user_id": str(result.inserted_id),
                    "college_id": u["college_id"],
                    "department": "Computer Science",
                    "semester": 4, "year": 2,
                    "skills": ["Python","Flutter","MongoDB"],
                    "interests": ["AI","Mobile Dev"],
                    "career_goals": ["Software Engineer","ML Engineer"],
                    "cgpa": 3.5,
                })
            elif u["role"] == "teacher":
                await db.teachers.insert_one({
                    "user_id": str(result.inserted_id),
                    "college_id": u["college_id"],
                    "department": "Computer Science",
                    "designation": "Associate Professor",
                })
