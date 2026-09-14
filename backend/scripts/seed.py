"""
Development seed script.
Creates 1 student, 1 teacher, and 1 admin user plus their profiles.

Usage:
    cd backend
    python -m scripts.seed

Safe to run multiple times — skips existing users.
"""
import asyncio
import sys
import os

# Allow running as: python -m scripts.seed from backend/
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings
from app.core.security import hash_password
from app.models.user import UserRole
from datetime import datetime


SEED_USERS = [
    {
        "name": "Arjun Sharma",
        "email": "student@prok.edu",
        "password": "student123",
        "role": UserRole.student.value,
        "college_id": "STU2024001",
        "profile_collection": "students",
        "profile": {
            "student_id": "STU2024001",
            "department": "Computer Science",
            "year": 2,
            "semester": 1,
            "gpa": 3.5,
            "enrolled_course_ids": [],
        },
    },
    {
        "name": "Dr. Priya Nair",
        "email": "teacher@prok.edu",
        "password": "teacher123",
        "role": UserRole.teacher.value,
        "college_id": "EMP2024001",
        "profile_collection": "teachers",
        "profile": {
            "employee_id": "EMP2024001",
            "department": "Computer Science",
            "designation": "Assistant Professor",
            "subjects": ["Data Structures", "Algorithms"],
            "course_ids": [],
        },
    },
    {
        "name": "PROK Admin",
        "email": "admin@prok.edu",
        "password": "admin123",
        "role": UserRole.admin.value,
        "college_id": "ADM2024001",
        "profile_collection": "admins",
        "profile": {
            "employee_id": "ADM2024001",
            "department": "Administration",
            "permissions": ["all"],
        },
    },
]


async def seed() -> None:
    client = AsyncIOMotorClient(settings.MONGO_URI)
    db = client[settings.MONGO_DB]
    now = datetime.utcnow()

    print(f"\nConnecting to {settings.MONGO_URI} / {settings.MONGO_DB}")
    await client.admin.command("ping")
    print("Connected.\n")

    for entry in SEED_USERS:
        existing = await db.users.find_one({"email": entry["email"]})
        if existing:
            print(f"  [SKIP] {entry['email']} already exists")
            continue

        # Insert into users collection
        user_doc = {
            "name": entry["name"],
            "email": entry["email"],
            "hashed_password": hash_password(entry["password"]),
            "role": entry["role"],
            "is_active": True,
            "college_id": entry["college_id"],
            "created_at": now,
        }
        result = await db.users.insert_one(user_doc)
        user_id = str(result.inserted_id)

        # Insert extended profile
        profile_doc = {
            "user_id": user_id,
            **entry["profile"],
            "created_at": now,
            "updated_at": now,
        }
        await db[entry["profile_collection"]].insert_one(profile_doc)

        print(f"  [CREATED] {entry['role']:8s}  {entry['email']}  /  password: {entry['password']}")

    client.close()
    print("\nSeeding complete.")
    print("\nDemo accounts:")
    print("  student@prok.edu   /  student123")
    print("  teacher@prok.edu   /  teacher123")
    print("  admin@prok.edu     /  admin123")


if __name__ == "__main__":
    asyncio.run(seed())
