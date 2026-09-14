from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.connection import get_db
import time

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check(db: AsyncIOMotorDatabase = Depends(get_db)):
    """API and database health check."""
    try:
        await db.command("ping")
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"

    return {
        "status": "ok",
        "service": "PROK Backend",
        "database": db_status,
        "timestamp": int(time.time()),
    }


@router.get("/")
async def root():
    return {"message": "PROK API is running. Visit /docs for API documentation."}
