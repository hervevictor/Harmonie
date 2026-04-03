from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from core.auth import get_current_user
from core.supabase_client import get_supabase
from services.pipeline import run_full_analysis_pipeline
import time

router = APIRouter(prefix="/analyses", tags=["Analyses"])


@router.post("/start", summary="Lance une analyse IA sur un fichier")
async def start_analysis(
    payload: dict,
    background_tasks: BackgroundTasks,
    user: dict = Depends(get_current_user)
):
    """
    Lance le pipeline d'analyse complet en arrière-plan.

    **Corps** : `{ file_id: uuid, instrument_id?: uuid }`
    **Sortie** : `{ analysis_id, status: "pending" }`

    Le pipeline inclut :
    - Basic Pitch (transcription audio → notes)
    - Librosa (tempo, tonalité)
    - ACRCloud (identification chanson, optionnel)
    - music21 (génération accords)
    """
    user_id = user["sub"]
    db = get_supabase()

    file_record = db.table("files").select("*")\
        .eq("id", payload["file_id"])\
        .eq("user_id", user_id)\
        .single().execute()

    if not file_record.data:
        raise HTTPException(404, "Fichier introuvable")

    analysis = db.table("analyses").insert({
        "file_id": payload["file_id"],
        "user_id": user_id,
        "instrument_id": payload.get("instrument_id"),
        "status": "pending"
    }).execute()

    analysis_id = analysis.data[0]["id"]

    background_tasks.add_task(
        run_full_analysis_pipeline,
        analysis_id=analysis_id,
        file_record=file_record.data
    )

    return {"analysis_id": analysis_id, "status": "pending", "message": "Analyse en cours..."}


@router.get("/{analysis_id}", summary="Récupère les résultats d'une analyse")
async def get_analysis(analysis_id: str, user: dict = Depends(get_current_user)):
    """
    **Statuts possibles** : `pending`, `processing`, `completed`, `error`
    """
    db = get_supabase()
    record = db.table("analyses").select("*, files(original_name, file_type), instruments(name)")\
        .eq("id", analysis_id)\
        .eq("user_id", user["sub"])\
        .single().execute()
    if not record.data:
        raise HTTPException(404, "Analyse introuvable")
    return record.data


@router.get("/", summary="Liste les analyses de l'utilisateur")
async def list_analyses(
    status: str = None,
    limit: int = 10,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("analyses").select("*, files(original_name)")\
        .eq("user_id", user["sub"])
    if status:
        query = query.eq("status", status)
    result = query.order("created_at", desc=True).limit(limit).execute()
    return {"analyses": result.data}


@router.post("/{analysis_id}/transpose", summary="Transpose une analyse vers une autre gamme")
async def transpose_analysis(
    analysis_id: str,
    payload: dict,
    user: dict = Depends(get_current_user)
):
    """
    **Corps** : `{ target_key: "G major" }`
    **Sortie** : notes transposées + nouveaux accords
    """
    from services.ai_harmony.music21_service import transpose_notes, get_chords_from_notes_sequence

    db = get_supabase()
    analysis = db.table("analyses").select("*")\
        .eq("id", analysis_id).eq("user_id", user["sub"])\
        .single().execute()

    if not analysis.data or analysis.data["status"] != "completed":
        raise HTTPException(400, "Analyse non disponible ou non terminée")

    data = analysis.data
    target_key = payload.get("target_key", "C major")

    result = transpose_notes(data["notes_sequence"], data["detected_key"], target_key)
    new_chords = get_chords_from_notes_sequence(result["notes_sequence"], target_key)

    return {
        "analysis_id": analysis_id,
        "original_key": data["detected_key"],
        "target_key": target_key,
        "transposed_notes": result["notes_sequence"],
        "new_chords": new_chords,
        "interval": result.get("interval", ""),
        "semitones": result.get("semitones", 0)
    }
