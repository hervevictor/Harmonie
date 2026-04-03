from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
from config import settings
from routers import (
    files, analyses, harmony, scores,
    instruments, courses, quiz, playbacks, subscriptions
)

# Créer le répertoire temporaire
os.makedirs(settings.TEMP_DIR, exist_ok=True)

app = FastAPI(
    title="Music AI API",
    description="API d'analyse musicale alimentée par l'IA",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # Restreindre en production : ["https://yourapp.com"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(files.router,         prefix="/api/v1", tags=["📁 Fichiers"])
app.include_router(analyses.router,      prefix="/api/v1", tags=["🔬 Analyses"])
app.include_router(harmony.router,       prefix="/api/v1", tags=["🎼 Harmonie"])
app.include_router(scores.router,        prefix="/api/v1", tags=["📄 Partitions"])
app.include_router(instruments.router,   prefix="/api/v1", tags=["🎸 Instruments"])
app.include_router(courses.router,       prefix="/api/v1", tags=["📚 Cours"])
app.include_router(quiz.router,          prefix="/api/v1", tags=["❓ Quiz"])
app.include_router(playbacks.router,     prefix="/api/v1", tags=["▶️ Playback"])
app.include_router(subscriptions.router, prefix="/api/v1", tags=["💳 Abonnements"])

@app.get("/health", tags=["Système"])
async def health_check():
    return {"status": "ok", "version": "1.0.0", "env": settings.APP_ENV}
