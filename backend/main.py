import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from config import settings
from database import init_db
from routers import documents, query, workflow


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="DOCent",
    description="AI-Powered Document Question Answering System",
    version="1.0.0",
    lifespan=lifespan,
)

allowed_origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(documents.router, prefix="/api")
app.include_router(query.router, prefix="/api")
app.include_router(workflow.router, prefix="/api")


@app.get("/api/health")
async def health():
    return {"status": "ok"}


# Serve the built React frontend from the same origin when present (Docker/HF Spaces).
# Skipped during local dev where Vite serves the frontend on its own port.
frontend_dist = os.getenv("FRONTEND_DIST", "/app/frontend_dist")
if os.path.isdir(frontend_dist):
    app.mount("/", StaticFiles(directory=frontend_dist, html=True), name="frontend")
