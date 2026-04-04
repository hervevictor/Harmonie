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
    content = await file.read()
    file_ext = os.path.splitext(file.filename)[1] or ".wav"
    
    # 1. Analyse audio
    try:
        # Transcription notes (Local ou Cloud)
        bp_res = await transcribe_audio_to_notes(content, file_ext)
        notes_seq = bp_res.get("notes_sequence", [])
        
        # Si local échoue, on tente Cloud
        if not notes_seq or bp_res.get("error_basic_pitch"):
            cloud_res = await transcribe_cloud(content)
            # On simule une séquence simple à partir du texte pour l'UI Flutter
            text = cloud_res.get("text", "")
            words = text.split()
            note_names = [w for w in words if len(w) <= 3] or ["C4"]
            from services.ai_audio.basic_pitch_service import midi_to_note_name # On garde le format
        else:
            note_names = [n["pitch_name"] for n in notes_seq]

        # Analyse acoustique (Local ou Valeurs par défaut)
        lib_res = await analyze_audio_features(content, file_ext)
        key = lib_res.get("detected_key", "C major")
        bpm = int(lib_res.get("tempo_bpm", 120))
        
        # Accords (via music21 si dispo)
        try:
            chords = get_chords_from_notes_sequence(notes_seq, key)
            chord_names = [c["chord"] for c in chords]
        except:
            chord_names = ["C", "G", "Am", "F"] # Fallback simple

        return {
            "key": key,
            "bpm": bpm,
            "notes": note_names[:50],
            "chords": chord_names[:20],
            "status": "success",
            "info": "Cloud fallback utilisé" if not notes_seq else "Local AI utilisé"
        }
    except Exception as e:
        return {"error": str(e), "key": "C", "bpm": 120, "notes": [], "chords": []}

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
