from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.db.connection import connect_db, close_db
from app.db.init_db import init_db
from app.routers import health, auth, attendance, documents, scholarships, courses, notifications, dashboard, admin
import os

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    await init_db()
    yield
    await close_db()

app = FastAPI(title="PROK API", version="3.0.0", lifespan=lifespan)

app.add_middleware(CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"])

os.makedirs("uploads", exist_ok=True)
app.mount("/files", StaticFiles(directory="uploads"), name="files")

for router in [health.router, auth.router, attendance.router, documents.router,
               scholarships.router, courses.router, notifications.router,
               dashboard.router, admin.router]:
    app.include_router(router)
