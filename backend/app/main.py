from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import settings
from app.db.connection import connect_db, close_db, db_state
from app.db.init_db import init_db
from app.routers import health, auth, demo


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    await init_db(db_state.db)   # create collections + indexes
    yield
    await close_db()


app = FastAPI(
    title="PROK API",
    description="Predictive and Responsible Operations For Knowledge – Backend",
    version="0.2.0",
    lifespan=lifespan,
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(demo.router)


@app.get("/", tags=["Root"])
async def root():
    return {
        "app": "PROK API",
        "version": "0.2.0",
        "status": "running",
        "docs": "/docs",
    }
