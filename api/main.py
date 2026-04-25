"""
Music Analysis API — Application principale
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import os
import sys

# Ajouter le dossier actuel au path pour les imports relatifs
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from fastapi.staticfiles import StaticFiles

# S'assurer que le dossier des exports existe
os.makedirs("exports", exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s"
)

app = FastAPI(
    title="Harmonie Core API",
    description="Cœur du système d'analyse musicale multi-modal.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from routers.analyze_router import router
from routers.instruments import router as instruments_router
app.include_router(router)
app.include_router(instruments_router)

# Servir les fichiers générés (partitions, etc.)
app.mount("/exports", StaticFiles(directory="exports"), name="exports")

@app.get("/")
async def root():
    return {
        "name": "Harmonie Core API",
        "status": "online",
        "endpoints": ["/api/analyze", "/api/health", "/api/jobs/{id}"]
    }
