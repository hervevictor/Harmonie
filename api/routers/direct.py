from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import List, Optional
import uuid, os
from core.storage import upload_to_storage, download_from_storage
from core.supabase_client import get_supabase
from services.ai_audio.basic_pitch_service import transcribe_audio_to_notes
from services.ai_audio.librosa_service import analyze_audio_features
from services.ai_score.gpt4o_vision_service import read_score_from_image, read_score_from_pdf
from services.ai_harmony.music21_service import get_chords_from_notes_sequence
from services.ai_pedagogy.whisper_service import transcribe_audio_answer as transcribe_cloud

router = APIRouter(tags=["Legacy Direct Routes"])

@router.post("/analyse")
async def analyse_file_direct(
    file: UploadFile = File(...),
    instrument: str = Form(...),
    file_type: str = Form("audio")
):
    """
    Endpoint direct pour l'application Flutter.
    Réalise l'analyse complète de façon synchrone.
    """
    try:
        content = await file.read()
        file_ext = os.path.splitext(file.filename)[1] or ".wav"
        
        # 1. Transcription notes (Local)
        bp_res = await transcribe_audio_to_notes(content, file_ext)
        if bp_res.get("error_basic_pitch"):
            raise Exception(f"IA Local en panne: {bp_res['error_basic_pitch']}")
            
        notes_seq = bp_res.get("notes_sequence", [])
        note_names = [n["pitch_name"] for n in notes_seq]

        # 2. Analyse acoustique (Librosa)
        lib_res = await analyze_audio_features(content, file_ext)
        if lib_res.get("error_librosa"):
            raise Exception(f"Analyse audio en panne: {lib_res['error_librosa']}")
            
        key = lib_res.get("detected_key", "Non détectée")
        bpm = int(lib_res.get("tempo_bpm", 0))
        
        # 3. Accords (via music21)
        try:
            chords = get_chords_from_notes_sequence(notes_seq, key)
            chord_names = [c["chord"] for c in chords]
        except Exception as chord_err:
            chord_names = [] # Pas d'accords au lieu de faux accords
            print(f"Erreur accords: {chord_err}")

        return {
            "key": key,
            "bpm": bpm,
            "notes": note_names[:50],
            "chords": chord_names[:20],
            "status": "success",
            "info": "Local AI utilisé (basic-pitch + librosa)"
        }
    except Exception as e:
        # On renvoie la vraie erreur au lieu de mentir !
        return {
            "status": "error",
            "error": str(e),
            "key": "N/A",
            "bpm": 0,
            "notes": [],
            "chords": [],
            "details": "L'IA n'a pas pu traiter ce fichier. Vérifie le format ou le diagnostic serveur."
        }

@router.post("/partition")
async def analyse_partition_direct(
    file: UploadFile = File(...),
    instrument: str = Form(...)
):
    """
    Endpoint direct pour les partitions.
    """
    content = await file.read()
    mime = file.content_type
    
    try:
        if "pdf" in mime:
            res = await read_score_from_pdf(content)
        else:
            res = await read_score_from_image(content, mime)
            
        return {
            "key": res.get("detected_key", "C"),
            "bpm": res.get("tempo_bpm", 120),
            "notes": [n["pitch"] for n in res.get("notes_sequence", [])],
            "chords": res.get("chords_sequence", []),
            "status": "success"
        }
    except Exception as e:
        return {"error": str(e), "key": "C", "bpm": 120, "notes": [], "chords": []}

@router.get("/health")
async def health_check():
    return {"status": "ok"}
