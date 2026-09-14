from motor.motor_asyncio import AsyncIOMotorDatabase
from app.models.user import UserInDB, UserRole
from app.schemas.user import UserRegister, UserOut
from app.core.security import hash_password, verify_password, create_access_token
from bson import ObjectId
from typing import Optional


def _doc_to_user_out(doc: dict) -> UserOut:
    return UserOut(
        id=str(doc["_id"]),
        name=doc["name"],
        email=doc["email"],
        role=doc["role"],
        is_active=doc.get("is_active", True),
        college_id=doc.get("college_id"),
    )


async def register_user(db: AsyncIOMotorDatabase, data: UserRegister) -> dict:
    existing = await db.users.find_one({"email": data.email})
    if existing:
        raise ValueError("Email already registered")

    doc = {
        "name": data.name,
        "email": data.email,
        "hashed_password": hash_password(data.password),
        "role": data.role.value,
        "is_active": True,
        "college_id": data.college_id,
    }
    result = await db.users.insert_one(doc)
    doc["_id"] = result.inserted_id
    user_out = _doc_to_user_out(doc)
    token = create_access_token({"sub": str(result.inserted_id), "role": data.role.value})
    return {"access_token": token, "token_type": "bearer", "user": user_out}


async def login_user(db: AsyncIOMotorDatabase, email: str, password: str) -> dict:
    doc = await db.users.find_one({"email": email})
    if not doc or not verify_password(password, doc["hashed_password"]):
        raise ValueError("Invalid credentials")
    if not doc.get("is_active", True):
        raise ValueError("Account is deactivated")

    user_out = _doc_to_user_out(doc)
    token = create_access_token({"sub": str(doc["_id"]), "role": doc["role"]})
    return {"access_token": token, "token_type": "bearer", "user": user_out}


async def get_user_by_id(db: AsyncIOMotorDatabase, user_id: str) -> Optional[UserOut]:
    try:
        doc = await db.users.find_one({"_id": ObjectId(user_id)})
    except Exception:
        return None
    if not doc:
        return None
    return _doc_to_user_out(doc)
