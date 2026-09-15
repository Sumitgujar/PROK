import pytest

@pytest.mark.asyncio
async def test_health(client):
    r = await client.get("/")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"

@pytest.mark.asyncio
async def test_login(client):
    r = await client.post("/auth/login", json={"email": "admin@prok.edu", "password": "admin123"})
    assert r.status_code == 200
    assert "access_token" in r.json()

@pytest.mark.asyncio
async def test_login_invalid(client):
    r = await client.post("/auth/login", json={"email": "bad@prok.edu", "password": "wrong"})
    assert r.status_code == 401

@pytest.mark.asyncio
async def test_me(client):
    login = await client.post("/auth/login", json={"email": "student@prok.edu", "password": "student123"})
    token = login.json()["access_token"]
    r = await client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["role"] == "student"
