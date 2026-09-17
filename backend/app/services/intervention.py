from __future__ import annotations

from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException

from app.db.connection import get_database
from app.services.intelligence_rules import validate_intervention_status


async def create_intervention(student_id: str, issue: str, recommendation: str, action: str, status: str, actor_id: str, outcome: str | None = None):
    db = get_database()
    normalized_status = validate_intervention_status(status)
    payload = {
        "student_id": student_id,
        "issue": issue.strip(),
        "recommendation": recommendation.strip(),
        "action": action.strip(),
        "status": normalized_status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "outcome": outcome,
        "created_by": actor_id,
        "updated_by": actor_id,
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "decision_note": "PROK provides recommendations and explanations. Humans make final decisions.",
    }
    result = await db.interventions.insert_one(payload)
    payload["_id"] = str(result.inserted_id)
    return payload


async def update_intervention(intervention_id: str, updates: dict, actor_id: str):
    db = get_database()
    intervention = await db.interventions.find_one({"_id": ObjectId(intervention_id)})
    if not intervention:
        raise HTTPException(status_code=404, detail="Intervention not found")

    allowed_fields = {"issue", "recommendation", "action", "status", "outcome"}
    set_fields = {key: value for key, value in updates.items() if key in allowed_fields and value is not None}
    if "status" in set_fields:
        set_fields["status"] = validate_intervention_status(set_fields["status"])
    if not set_fields:
        raise HTTPException(status_code=400, detail="No valid fields provided for update")

    set_fields["updated_by"] = actor_id
    set_fields["updated_at"] = datetime.now(timezone.utc).isoformat()
    await db.interventions.update_one({"_id": ObjectId(intervention_id)}, {"$set": set_fields})
    updated = await db.interventions.find_one({"_id": ObjectId(intervention_id)})
    updated["_id"] = str(updated["_id"])
    return updated


async def list_interventions(student_id: str | None = None, status: str | None = None):
    db = get_database()
    query = {}
    if student_id:
        query["student_id"] = student_id
    if status:
        query["status"] = validate_intervention_status(status)
    items = await db.interventions.find(query).sort("timestamp", -1).to_list(None)
    for item in items:
        item["_id"] = str(item["_id"])
    return items


async def get_intervention(intervention_id: str):
    db = get_database()
    item = await db.interventions.find_one({"_id": ObjectId(intervention_id)})
    if not item:
        raise HTTPException(status_code=404, detail="Intervention not found")
    item["_id"] = str(item["_id"])
    return item
