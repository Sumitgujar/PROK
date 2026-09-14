from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)


class Database:
    client: AsyncIOMotorClient = None
    db: AsyncIOMotorDatabase = None


db_state = Database()


async def connect_db():
    """Create MongoDB connection."""
    logger.info(f"Connecting to MongoDB at {settings.MONGO_URI}")
    db_state.client = AsyncIOMotorClient(settings.MONGO_URI)
    db_state.db = db_state.client[settings.MONGO_DB]
    # Ping to verify connection
    await db_state.client.admin.command("ping")
    logger.info(f"Connected to MongoDB database: {settings.MONGO_DB}")


async def close_db():
    """Close MongoDB connection."""
    if db_state.client:
        db_state.client.close()
        logger.info("MongoDB connection closed.")


def get_db() -> AsyncIOMotorDatabase:
    """Dependency: return the active database instance."""
    return db_state.db
