from app.db.connection import get_database
from app.core.security import verify_password, create_access_token, hash_password
from fastapi import HTTPException
from bson import ObjectId
import re

def _serialize(user):
    u = dict(user)
    u["_id"] = str(u["_id"])
    u.pop("hashed_password", None)
    return u

async def authenticate_user(email: str, password: str):
    db = get_database()
    user = await db.users.find_one({"email": email.lower()})
    if not user or not verify_password(password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user.get("is_active", True):
        raise HTTPException(status_code=403, detail="Account disabled")
    token = create_access_token({"sub": str(user["_id"]), "role": user["role"]})
    return {"access_token": token, "token_type": "bearer", "user": _serialize(user)}

async def register_user(data: dict):
    db = get_database()
    if await db.users.find_one({"email": data["email"].lower()}):
        raise HTTPException(status_code=409, detail="Email already registered")
    from datetime import datetime, timezone
    result = await db.users.insert_one({
        "email": data["email"].lower(),
        "hashed_password": hash_password(data["password"]),
        "role": data.get("role", "student"),
        "full_name": data["full_name"],
        "college_id": data["college_id"],
        "is_active": True,
        "created_at": datetime.now(timezone.utc),
    })
    return {"id": str(result.inserted_id), "message": "User created"}
