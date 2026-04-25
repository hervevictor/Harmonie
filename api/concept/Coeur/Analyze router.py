"""
ROUTER UNIFIÉ — Un seul endpoint pour tout
==========================================
POST /api/analyze          → détecte le type automatiquement
POST /api/analyze/audio    → forcer pipeline audio
POST /api/analyze/video    → forcer pipeline vidéo
POST /api/analyze/image    → forcer pipeline image/partition
POST /api/analyze/mic      → pipeline enregistrement
GET  /api/jobs/{id}        → récupérer un job
GET  /api/health           → status complet
"""

import os
import magic
import tempfile
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from typing import Optional

from core.orchestrator import orchestrator, InputType, MusicResult

router = APIRouter(prefix="/api", tags=["Music Analysis"])

# Extensions reconnues par pipeline
AUDIO_EXT  = {".mp3", ".wav", ".flac", ".ogg", ".m4a", ".aac", ".wma"}
VIDEO_EXT  = {".mp4", ".mkv", ".avi", ".mov", ".webm", ".m4v"}
IMAGE_EXT  = {".png", ".jpg", ".jpeg", ".webp", ".pdf", ".tiff"}
MAX_MB     = 100


# ──────────────────────────────────────────
# Utilitaires
# ──────────────────────────────────────────

def detect_input_type(filename: str, content_type: str = "") -> InputType:
    """Détecte le type d'entrée depuis l'extension ou le MIME."""
    ext = os.path.splitext(filename.lower())[1]
    if ext in AUDIO_EXT or "audio" in content_type:
        return InputType.AUDIO
    if ext in VIDEO_EXT or "video" in content_type:
        return InputType.VIDEO
    if ext in IMAGE_EXT or "image" in content_type or "pdf" in content_type:
        return InputType.IMAGE
    # Fallback : essayer audio
    return InputType.AUDIO


def validate_file(file: UploadFile, content: bytes, force_type: Optional[InputType] = None):
    size_mb = len(content) / (1024 * 1024)
    if size_mb > MAX_MB:
        raise HTTPException(413, f"Fichier trop grand ({size_mb:.1f} MB). Max: {MAX_MB} MB")

    ext = os.path.splitext(file.filename or "")[1].lower()
    all_exts = AUDIO_EXT | VIDEO_EXT | IMAGE_EXT
    if ext not in all_exts:
        raise HTTPException(400, f"Format non supporté: '{ext}'")

    return size_mb


async def save_upload(content: bytes, filename: str) -> str:
    """Sauvegarde l'upload dans un fichier temporaire."""
    ext = os.path.splitext(filename)[1] or ".tmp"
    tmp = tempfile.NamedTemporaryFile(suffix=ext, delete=False)
    tmp.write(content)
    tmp.close()
    return tmp.name


def result_to_response(result: MusicResult) -> dict:
    """Convertit MusicResult en dict JSON propre."""
    d = result.to_dict()
    # Truncate MusicXML (trop long pour l'API, accessible séparément)
    if d.get("harmony") and d["harmony"].get("musicxml"):
        d["harmony"]["musicxml_available"] = True
        d["harmony"]["musicxml"] = None
    return d


# ──────────────────────────────────────────
# Health check
# ──────────────────────────────────────────

@router.get("/health")
async def health():
    deps = {}

    for lib, ver_attr in [("librosa", "__version__"), ("music21", "__version__"),
                          ("numpy", "__version__"), ("scipy", "__version__")]:
        try:
            mod = __import__(lib)
            deps[lib] = getattr(mod, ver_attr, "ok")
        except ImportError:
            deps[lib] = "manquant"

    for lib in ["basic_pitch", "whisper", "cv2"]:
        try:
            __import__(lib)
            deps[lib] = "disponible"
        except ImportError:
            deps[lib] = "non installé (optionnel)"

    import subprocess
    r = subprocess.run(["ffmpeg", "-version"], capture_output=True)
    deps["ffmpeg"] = "disponible" if r.returncode == 0 else "non installé"

    deps["openai_key"] = "configurée" if os.getenv("OPENAI_API_KEY") else "manquante"
    deps["anthropic_key"] = "configurée" if os.getenv("ANTHROPIC_API_KEY") else "manquante"

    return {
        "status": "ok",
        "pipelines": {
            "audio":  "FFmpeg → Librosa → Basic Pitch → music21",
            "video":  "FFmpeg → Whisper + Basic Pitch → music21",
            "image":  "OpenCV → GPT-4o Vision → music21",
            "mic":    "PyAudio → Basic Pitch → music21",
        },
        "dependencies": deps,
    }


# ──────────────────────────────────────────
# Endpoint auto-détection
# ──────────────────────────────────────────

@router.post("/analyze")
async def analyze_auto(
    file: UploadFile = File(...),
    target_key: Optional[str] = Form(None),
    openai_api_key: Optional[str] = Form(None),
):
    """
    Endpoint universel — détecte automatiquement le type de fichier
    et lance le pipeline adapté.
    """
    content = await file.read()
    size_mb = validate_file(file, content)
    input_type = detect_input_type(file.filename or "", file.content_type or "")

    tmp_path = await save_upload(content, file.filename or "upload.tmp")
    try:
        result = await orchestrator.process(
            input_type=input_type,
            file_path=tmp_path,
            filename=file.filename or "",
            size_mb=size_mb,
            options={
                "target_key": target_key,
                "openai_api_key": openai_api_key or os.getenv("OPENAI_API_KEY", ""),
            }
        )
        return JSONResponse(content=result_to_response(result))
    finally:
        os.unlink(tmp_path)


# ──────────────────────────────────────────
# Endpoints par type (forcer le pipeline)
# ──────────────────────────────────────────

@router.post("/analyze/audio")
async def analyze_audio(
    file: UploadFile = File(...),
    target_key: Optional[str] = Form(None),
):
    content = await file.read()
    size_mb = validate_file(file, content, InputType.AUDIO)
    tmp_path = await save_upload(content, file.filename or "audio.wav")
    try:
        result = await orchestrator.process(
            InputType.AUDIO, tmp_path,
            filename=file.filename or "", size_mb=size_mb,
            options={"target_key": target_key}
        )
        return JSONResponse(content=result_to_response(result))
    finally:
        os.unlink(tmp_path)


@router.post("/analyze/video")
async def analyze_video(
    file: UploadFile = File(...),
    target_key: Optional[str] = Form(None),
    openai_api_key: Optional[str] = Form(None),
):
    content = await file.read()
    size_mb = validate_file(file, content, InputType.VIDEO)
    tmp_path = await save_upload(content, file.filename or "video.mp4")
    try:
        result = await orchestrator.process(
            InputType.VIDEO, tmp_path,
            filename=file.filename or "", size_mb=size_mb,
            options={
                "target_key": target_key,
                "openai_api_key": openai_api_key or os.getenv("OPENAI_API_KEY", ""),
            }
        )
        return JSONResponse(content=result_to_response(result))
    finally:
        os.unlink(tmp_path)


@router.post("/analyze/image")
async def analyze_image(
    file: UploadFile = File(...),
    openai_api_key: Optional[str] = Form(None),
):
    """Analyse d'une partition (PDF, photo, scan)."""
    content = await file.read()
    size_mb = validate_file(file, content, InputType.IMAGE)
    tmp_path = await save_upload(content, file.filename or "sheet.png")
    try:
        result = await orchestrator.process(
            InputType.IMAGE, tmp_path,
            filename=file.filename or "", size_mb=size_mb,
            options={
                "openai_api_key": openai_api_key or os.getenv("OPENAI_API_KEY", ""),
            }
        )
        return JSONResponse(content=result_to_response(result))
    finally:
        os.unlink(tmp_path)


@router.post("/analyze/mic")
async def analyze_mic(file: UploadFile = File(...)):
    """Analyse d'un enregistrement microphone."""
    content = await file.read()
    size_mb = validate_file(file, content, InputType.MIC)
    tmp_path = await save_upload(content, file.filename or "mic.wav")
    try:
        result = await orchestrator.process(
            InputType.MIC, tmp_path,
            filename="live_recording.wav", size_mb=size_mb,
        )
        return JSONResponse(content=result_to_response(result))
    finally:
        os.unlink(tmp_path)


# ──────────────────────────────────────────
# Job status (pour async futur)
# ──────────────────────────────────────────

@router.get("/jobs/{job_id}")
async def get_job(job_id: str):
    result = orchestrator.get_job(job_id)
    if not result:
        raise HTTPException(404, f"Job '{job_id}' introuvable")
    return JSONResponse(content=result_to_response(result))


@router.get("/jobs")
async def list_jobs():
    jobs = orchestrator._jobs
    return {
        "total": len(jobs),
        "jobs": [
            {
                "job_id": r.job_id,
                "status": r.status,
                "input_type": r.input_type,
                "filename": r.source_filename,
                "duration_ms": r.total_duration_ms,
            }
            for r in jobs.values()
        ]
    }