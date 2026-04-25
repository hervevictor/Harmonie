"""
Music Analysis API — Application principale
============================================
Lance : uvicorn main:app --reload --port 8000
Docs  : http://localhost:8000/docs
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s"
)

app = FastAPI(
    title="Music Analysis Core API",
    description="""
## Cœur du système d'analyse musicale

Pipeline multi-modal :
- **Audio** (.mp3, .wav, .flac...) → FFmpeg → Librosa → Basic Pitch → music21
- **Vidéo** (.mp4, .mkv...) → FFmpeg extract → Whisper (paroles) + Basic Pitch → music21  
- **Image/Partition** (.png, .jpg, .pdf) → OpenCV → GPT-4o Vision → music21
- **Microphone** (live WAV) → Basic Pitch → music21

### Variables d'environnement
```
OPENAI_API_KEY=sk-...     # pour GPT-4o Vision + Whisper
ANTHROPIC_API_KEY=sk-...  # pour les cours + quiz (phase 2)
```
    """,
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from routers.analyze_router import router
app.include_router(router)


@app.get("/")
async def root():
    return {
        "name": "Music Analysis Core API",
        "version": "1.0.0",
        "usage": {
            "auto":  "POST /api/analyze          — détecte le type automatiquement",
            "audio": "POST /api/analyze/audio    — pipeline audio",
            "video": "POST /api/analyze/video    — pipeline vidéo",
            "image": "POST /api/analyze/image    — partition PDF/image",
            "mic":   "POST /api/analyze/mic      — enregistrement micro",
            "jobs":  "GET  /api/jobs             — historique",
            "health":"GET  /api/health           — status dépendances",
            "docs":  "GET  /docs                 — Swagger UI",
        }
    }