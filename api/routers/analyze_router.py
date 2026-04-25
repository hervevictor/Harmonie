"""
ROUTER UNIFIÉ — Points d'entrée API
==================================
"""

import os
import tempfile
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from typing import Optional

from core.orchestrator import orchestrator, InputType, MusicResult

router = APIRouter(prefix="/api", tags=["Music Analysis"])

AUDIO_EXT  = {".mp3", ".wav", ".flac", ".ogg", ".m4a", ".aac", ".wma"}
VIDEO_EXT  = {".mp4", ".mkv", ".avi", ".mov", ".webm", ".m4v"}
IMAGE_EXT  = {".png", ".jpg", ".jpeg", ".webp", ".pdf", ".tiff"}
MAX_MB     = 100

def detect_input_type(filename: str, content_type: str = "") -> InputType:
    ext = os.path.splitext(filename.lower())[1]
    if ext in AUDIO_EXT or "audio" in content_type: return InputType.AUDIO
    if ext in VIDEO_EXT or "video" in content_type: return InputType.VIDEO
    if ext in IMAGE_EXT or "image" in content_type or "pdf" in content_type: return InputType.IMAGE
    return InputType.AUDIO

def validate_file(file: UploadFile, content: bytes):
    size_mb = len(content) / (1024 * 1024)
    if size_mb > MAX_MB: raise HTTPException(413, f"Fichier trop grand ({size_mb:.1f} MB)")
    return size_mb

async def save_upload(content: bytes, filename: str) -> str:
    ext = os.path.splitext(filename)[1] or ".tmp"
    tmp = tempfile.NamedTemporaryFile(suffix=ext, delete=False)
    tmp.write(content)
    tmp.close()
    return tmp.name

def result_to_response(result: MusicResult) -> dict:
    d = result.to_dict()
    if d.get("harmony") and d["harmony"].get("musicxml"):
        d["harmony"]["musicxml_available"] = True
        d["harmony"]["musicxml"] = None
    return d

@router.get("/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}

@router.post("/analyze")
async def analyze_auto(
    file: UploadFile = File(...),
    target_key: Optional[str] = Form(None),
    openai_api_key: Optional[str] = Form(None),
):
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
        if os.path.exists(tmp_path): os.unlink(tmp_path)

@router.post("/analyze/mic")
async def analyze_mic(
    file: UploadFile = File(...),
    target_key: Optional[str] = Form(None),
):
    """Endpoint dédié pour l'enregistrement microphone."""
    content = await file.read()
    size_mb = validate_file(file, content)
    tmp_path = await save_upload(content, file.filename or "live_recording.wav")
    try:
        result = await orchestrator.process(
            input_type=InputType.MIC,
            file_path=tmp_path,
            filename=file.filename or "live_recording.wav",
            size_mb=size_mb,
            options={
                "target_key": target_key,
            }
        )
        return JSONResponse(content=result_to_response(result))
    finally:
        if os.path.exists(tmp_path): os.unlink(tmp_path)

@router.get("/jobs/{job_id}")
async def get_job(job_id: str):
    result = orchestrator.get_job(job_id)
    if not result: raise HTTPException(404, "Job introuvable")
    return JSONResponse(content=result_to_response(result))
