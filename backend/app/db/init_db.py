"""
MongoDB collection initialisation.
Creates all 15 PROK collections and their indexes on first startup.
Safe to call on every startup — index creation is idempotent.
"""
from motor.motor_asyncio import AsyncIOMotorDatabase
import logging

logger = logging.getLogger(__name__)


async def init_db(db: AsyncIOMotorDatabase) -> None:
    """Create collections and indexes. Called once at app startup."""
    await _create_indexes(db)
    logger.info("Database initialisation complete.")


async def _create_indexes(db: AsyncIOMotorDatabase) -> None:
    # ── users ──────────────────────────────────────────────────────────────
    await db.users.create_index("email", unique=True)
    await db.users.create_index("role")
    logger.debug("users indexes created")

    # ── students ───────────────────────────────────────────────────────────
    await db.students.create_index("user_id", unique=True)
    await db.students.create_index("student_id", unique=True, sparse=True)
    await db.students.create_index("department")
    logger.debug("students indexes created")

    # ── teachers ───────────────────────────────────────────────────────────
    await db.teachers.create_index("user_id", unique=True)
    await db.teachers.create_index("employee_id", unique=True, sparse=True)
    await db.teachers.create_index("department")
    logger.debug("teachers indexes created")

    # ── admins ─────────────────────────────────────────────────────────────
    await db.admins.create_index("user_id", unique=True)
    logger.debug("admins indexes created")

    # ── courses ────────────────────────────────────────────────────────────
    await db.courses.create_index("course_code", unique=True)
    await db.courses.create_index("teacher_id")
    await db.courses.create_index("department")
    await db.courses.create_index([("semester", 1), ("year", 1)])
    logger.debug("courses indexes created")

    # ── enrollments ────────────────────────────────────────────────────────
    await db.enrollments.create_index(
        [("student_id", 1), ("course_id", 1)], unique=True
    )
    await db.enrollments.create_index("student_id")
    await db.enrollments.create_index("course_id")
    await db.enrollments.create_index("status")
    logger.debug("enrollments indexes created")

    # ── attendance_sessions ────────────────────────────────────────────────
    await db.attendance_sessions.create_index([("course_id", 1), ("date", -1)])
    await db.attendance_sessions.create_index("teacher_id")
    logger.debug("attendance_sessions indexes created")

    # ── attendance_records ─────────────────────────────────────────────────
    await db.attendance_records.create_index(
        [("session_id", 1), ("student_id", 1)], unique=True
    )
    await db.attendance_records.create_index("student_id")
    await db.attendance_records.create_index("session_id")
    logger.debug("attendance_records indexes created")

    # ── documents ──────────────────────────────────────────────────────────
    await db.documents.create_index("owner_id")
    await db.documents.create_index("doc_type")
    await db.documents.create_index("tags")
    logger.debug("documents indexes created")

    # ── scholarships ───────────────────────────────────────────────────────
    await db.scholarships.create_index("tags")
    await db.scholarships.create_index("deadline")
    await db.scholarships.create_index("is_active")
    logger.debug("scholarships indexes created")

    # ── scholarship_applications ───────────────────────────────────────────
    await db.scholarship_applications.create_index(
        [("scholarship_id", 1), ("student_id", 1)], unique=True
    )
    await db.scholarship_applications.create_index("student_id")
    await db.scholarship_applications.create_index("status")
    logger.debug("scholarship_applications indexes created")

    # ── recommendations ────────────────────────────────────────────────────
    await db.recommendations.create_index("student_id")
    await db.recommendations.create_index([("student_id", 1), ("rec_type", 1)])
    logger.debug("recommendations indexes created")

    # ── interventions ──────────────────────────────────────────────────────
    await db.interventions.create_index("student_id")
    await db.interventions.create_index("status")
    await db.interventions.create_index([("student_id", 1), ("status", 1)])
    logger.debug("interventions indexes created")

    # ── notifications ──────────────────────────────────────────────────────
    await db.notifications.create_index([("user_id", 1), ("is_read", 1)])
    await db.notifications.create_index("user_id")
    await db.notifications.create_index("created_at")
    logger.debug("notifications indexes created")

    # ── ai_conversations ───────────────────────────────────────────────────
    await db.ai_conversations.create_index("user_id")
    await db.ai_conversations.create_index("updated_at")
    logger.debug("ai_conversations indexes created")
