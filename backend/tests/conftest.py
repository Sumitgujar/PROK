"""
pytest shared fixtures.
DB is fully mocked — no live MongoDB required to run tests.
"""
import pytest
from contextlib import contextmanager
from unittest.mock import AsyncMock, MagicMock, patch
from bson import ObjectId
from fastapi.testclient import TestClient

from app.main import app
from app.db.connection import get_db
from app.core.security import hash_password, create_access_token
from app.models.user import UserRole

# ────────────────────────────── shared test data ──────────────────────────────

STUDENT_OID = ObjectId()
TEACHER_OID = ObjectId()
ADMIN_OID   = ObjectId()
TEST_PW     = "testpass123"

STUDENT_DOC = {
    "_id": STUDENT_OID,
    "name": "Alice Student",
    "email": "alice@test.prok",
    "hashed_password": hash_password(TEST_PW),
    "role": UserRole.student.value,
    "is_active": True,
    "college_id": "STU001",
}

TEACHER_DOC = {
    "_id": TEACHER_OID,
    "name": "Bob Teacher",
    "email": "bob@test.prok",
    "hashed_password": hash_password(TEST_PW),
    "role": UserRole.teacher.value,
    "is_active": True,
    "college_id": "EMP001",
}

ADMIN_DOC = {
    "_id": ADMIN_OID,
    "name": "Carol Admin",
    "email": "carol@test.prok",
    "hashed_password": hash_password(TEST_PW),
    "role": UserRole.admin.value,
    "is_active": True,
    "college_id": "ADM001",
}


# ────────────────────────────── helpers ───────────────────────────────────────

def build_mock_db(find_one_doc=None):
    """Return a Motor-compatible mock database."""
    mock = MagicMock()
    oid  = find_one_doc["_id"] if find_one_doc else ObjectId()
    mock.users.find_one    = AsyncMock(return_value=find_one_doc)
    mock.users.insert_one  = AsyncMock(return_value=MagicMock(inserted_id=oid))
    mock.users.create_index = AsyncMock()
    return mock


def bearer(user_id, role: UserRole) -> str:
    return create_access_token({"sub": str(user_id), "role": role.value})


@contextmanager
def make_client(find_one_doc=None):
    """
    Context manager that yields a TestClient with:
    - lifespan patched (no real MongoDB call)
    - get_db overridden to return a mock matching find_one_doc
    """
    mock_db = build_mock_db(find_one_doc)
    app.dependency_overrides[get_db] = lambda: mock_db
    try:
        with (
            patch("app.main.connect_db", new_callable=AsyncMock),
            patch("app.main.close_db",   new_callable=AsyncMock),
            patch("app.main.init_db",     new_callable=AsyncMock),
        ):
            with TestClient(app, raise_server_exceptions=True) as client:
                yield client, mock_db
    finally:
        app.dependency_overrides.clear()


# ────────────────────────────── fixtures ──────────────────────────────────────

@pytest.fixture
def student_token():
    return bearer(STUDENT_OID, UserRole.student)


@pytest.fixture
def teacher_token():
    return bearer(TEACHER_OID, UserRole.teacher)


@pytest.fixture
def admin_token():
    return bearer(ADMIN_OID, UserRole.admin)
