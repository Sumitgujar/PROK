from app.db.connection import get_database
from bson import ObjectId
from datetime import datetime, timezone

async def get_notifications(user_id: str):
    db = get_database()
    notes = await db.notifications.find({"recipient_id": user_id}).sort("created_at", -1).limit(50).to_list(None)
    for n in notes:
        n["_id"] = str(n["_id"])
    return notes

async def mark_read(notification_id: str, user_id: str):
    db = get_database()
    await db.notifications.update_one(
        {"_id": ObjectId(notification_id), "recipient_id": user_id},
        {"$set": {"is_read": True}}
    )
    return {"ok": True}

async def mark_all_read(user_id: str):
    db = get_database()
    await db.notifications.update_many(
        {"recipient_id": user_id, "is_read": {"$ne": True}},
        {"$set": {"is_read": True}}
    )
    return {"ok": True}

async def create_notification(recipient_id: str, title: str, message: str, ntype: str = "general"):
    db = get_database()
    result = await db.notifications.insert_one({
        "recipient_id": recipient_id,
        "title": title,
        "message": message,
        "ntype": ntype,
        "is_read": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    })
    return str(result.inserted_id)
