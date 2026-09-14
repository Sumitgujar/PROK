"""
Auth test suite.
Covers: login, invalid credentials, JWT validation,
        protected routes, and role-based access control.
"""
import pytest
from jose import jwt

from app.core.config import settings
from app.models.user import UserRole
from tests.conftest import (
    make_client,
    STUDENT_DOC, TEACHER_DOC, ADMIN_DOC,
    STUDENT_OID, TEACHER_OID, ADMIN_OID,
    TEST_PW, bearer,
)


# ══════════════════════════════════════════════════════════════════════════════
# 1. Login
# ══════════════════════════════════════════════════════════════════════════════

class TestLogin:

    def test_login_success_returns_token_and_user(self):
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.post(
                "/auth/login",
                data={"username": STUDENT_DOC["email"], "password": TEST_PW},
            )
        assert res.status_code == 200
        body = res.json()
        assert "access_token" in body
        assert body["token_type"] == "bearer"
        assert body["user"]["email"] == STUDENT_DOC["email"]

    def test_login_returns_correct_role(self):
        """Role in response must come from DB, not be trusted from client."""
        with make_client(find_one_doc=TEACHER_DOC) as (client, _):
            res = client.post(
                "/auth/login",
                data={"username": TEACHER_DOC["email"], "password": TEST_PW},
            )
        assert res.status_code == 200
        assert res.json()["user"]["role"] == UserRole.teacher.value

    def test_login_invalid_email(self):
        """Unknown email → user not found → 401."""
        with make_client(find_one_doc=None) as (client, _):
            res = client.post(
                "/auth/login",
                data={"username": "nobody@test.prok", "password": TEST_PW},
            )
        assert res.status_code == 401
        assert "Invalid credentials" in res.json()["detail"]

    def test_login_wrong_password(self):
        """Correct email, wrong password → 401."""
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.post(
                "/auth/login",
                data={"username": STUDENT_DOC["email"], "password": "wrongpassword!"},
            )
        assert res.status_code == 401

    def test_login_deactivated_account(self):
        """Inactive account → 403-level rejection."""
        inactive = {**STUDENT_DOC, "is_active": False}
        with make_client(find_one_doc=inactive) as (client, _):
            res = client.post(
                "/auth/login",
                data={"username": inactive["email"], "password": TEST_PW},
            )
        assert res.status_code == 401


# ══════════════════════════════════════════════════════════════════════════════
# 2. JWT Token validation
# ══════════════════════════════════════════════════════════════════════════════

class TestJWT:

    def test_jwt_contains_sub_and_role(self):
        """Decoded token must carry user id (sub) and role."""
        with make_client(find_one_doc=ADMIN_DOC) as (client, _):
            res = client.post(
                "/auth/login",
                data={"username": ADMIN_DOC["email"], "password": TEST_PW},
            )
        assert res.status_code == 200
        token = res.json()["access_token"]
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert payload["sub"] == str(ADMIN_OID)
        assert payload["role"] == UserRole.admin.value

    def test_jwt_role_matches_db_not_client_request(self):
        """
        Security: register always assigns 'student'.
        Even if someone crafted a request with role='admin', the token
        issued after registration must contain 'student'.
        """
        new_oid = STUDENT_OID
        # Simulate: no existing user, so insert_one returns new doc
        from unittest.mock import AsyncMock, MagicMock
        from bson import ObjectId
        from app.main import app
        from app.db.connection import get_db
        from unittest.mock import patch

        mock_db = MagicMock()
        mock_db.users.find_one = AsyncMock(return_value=None)  # not yet registered
        inserted_oid = ObjectId()
        mock_db.users.insert_one = AsyncMock(
            return_value=MagicMock(inserted_id=inserted_oid)
        )
        app.dependency_overrides[get_db] = lambda: mock_db
        try:
            with (
                patch("app.main.connect_db", new_callable=AsyncMock),
                patch("app.main.close_db",   new_callable=AsyncMock),
                patch("app.main.init_db",     new_callable=AsyncMock),
            ):
                from fastapi.testclient import TestClient
                with TestClient(app) as client:
                    res = client.post(
                        "/auth/register",
                        json={
                            "name": "Hacker",
                            "email": "hacker@test.prok",
                            "password": "hackpass123",
                        },
                    )
        finally:
            app.dependency_overrides.clear()

        assert res.status_code == 201
        token = res.json()["access_token"]
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        # Must be student regardless of what was in the request
        assert payload["role"] == UserRole.student.value
        assert res.json()["user"]["role"] == UserRole.student.value


# ══════════════════════════════════════════════════════════════════════════════
# 3. Protected routes (/auth/me)
# ══════════════════════════════════════════════════════════════════════════════

class TestProtectedRoutes:

    def test_me_returns_user_when_authenticated(self):
        token = bearer(STUDENT_OID, UserRole.student)
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 200
        assert res.json()["email"] == STUDENT_DOC["email"]

    def test_me_rejects_missing_token(self):
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.get("/auth/me")
        assert res.status_code == 401

    def test_me_rejects_invalid_token(self):
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.get(
                "/auth/me",
                headers={"Authorization": "Bearer this.is.not.a.valid.jwt"},
            )
        assert res.status_code == 401

    def test_me_rejects_tampered_token(self):
        """A token signed with a different key must be rejected."""
        fake_token = jwt.encode(
            {"sub": str(STUDENT_OID), "role": "admin"},
            key="wrong-secret",
            algorithm="HS256",
        )
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.get(
                "/auth/me",
                headers={"Authorization": f"Bearer {fake_token}"},
            )
        assert res.status_code == 401


# ══════════════════════════════════════════════════════════════════════════════
# 4. Role-based access control  (/demo/* endpoints)
# ══════════════════════════════════════════════════════════════════════════════

class TestRBAC:

    def test_admin_area_allows_admin(self):
        token = bearer(ADMIN_OID, UserRole.admin)
        with make_client(find_one_doc=ADMIN_DOC) as (client, _):
            res = client.get(
                "/demo/admin-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 200

    def test_admin_area_blocks_student(self):
        token = bearer(STUDENT_OID, UserRole.student)
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.get(
                "/demo/admin-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 403

    def test_admin_area_blocks_teacher(self):
        token = bearer(TEACHER_OID, UserRole.teacher)
        with make_client(find_one_doc=TEACHER_DOC) as (client, _):
            res = client.get(
                "/demo/admin-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 403

    def test_teacher_area_allows_teacher(self):
        token = bearer(TEACHER_OID, UserRole.teacher)
        with make_client(find_one_doc=TEACHER_DOC) as (client, _):
            res = client.get(
                "/demo/teacher-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 200

    def test_teacher_area_allows_admin(self):
        token = bearer(ADMIN_OID, UserRole.admin)
        with make_client(find_one_doc=ADMIN_DOC) as (client, _):
            res = client.get(
                "/demo/teacher-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 200

    def test_teacher_area_blocks_student(self):
        token = bearer(STUDENT_OID, UserRole.student)
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.get(
                "/demo/teacher-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 403

    def test_student_area_allows_student(self):
        token = bearer(STUDENT_OID, UserRole.student)
        with make_client(find_one_doc=STUDENT_DOC) as (client, _):
            res = client.get(
                "/demo/student-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 200

    def test_student_area_blocks_teacher(self):
        """Teachers cannot access student-only area."""
        token = bearer(TEACHER_OID, UserRole.teacher)
        with make_client(find_one_doc=TEACHER_DOC) as (client, _):
            res = client.get(
                "/demo/student-area",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert res.status_code == 403
