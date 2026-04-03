from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.supabase_client import get_supabase
from services.ai_pedagogy.claude_courses_service import generate_course_lesson
from schemas.course import CourseRequest
import uuid

router = APIRouter(prefix="/courses", tags=["Cours"])


@router.post("/generate", summary="Génère un cours adaptatif (IA Claude)")
async def generate_course(payload: CourseRequest, user: dict = Depends(get_current_user)):
    """
    Génère un cours musical complet et structuré via Claude.

    **Corps** :
    ```json
    {
      "instrument": "guitar",
      "topic": "La gamme pentatonique mineure",
      "level": "débutant",
      "analysis_id": "uuid-optionnel"
    }
    ```
    """
    user_id = user["sub"]
    db = get_supabase()

    # Récupérer le contexte de l'analyse si fourni
    analysis_context = None
    if payload.analysis_id:
        analysis = db.table("analyses").select("detected_key,tempo_bpm,chords_sequence")\
            .eq("id", payload.analysis_id).eq("user_id", user_id)\
            .maybe_single().execute()
        if analysis.data:
            analysis_context = analysis.data

    # Récupérer les cours précédents pour éviter les répétitions
    previous = db.table("courses_progress").select("topic")\
        .eq("user_id", user_id).eq("instrument_id", payload.instrument)\
        .execute()
    previous_topics = [r["topic"] for r in (previous.data or [])]

    # Générer le cours avec Claude
    course = await generate_course_lesson(
        instrument=payload.instrument,
        topic=payload.topic,
        level=payload.level,
        analysis_context=analysis_context,
        previous_lessons=previous_topics
    )

    if "error" in course:
        raise HTTPException(502, f"Erreur génération cours : {course['error']}")

    # Sauvegarder la progression
    db.table("courses_progress").upsert({
        "user_id": user_id,
        "instrument_id": payload.instrument,
        "topic": payload.topic,
        "level": payload.level,
        "course_data": course,
        "completed": False,
        "completion_percentage": 0
    }, on_conflict="user_id,instrument_id,topic,level").execute()

    return course


@router.get("/", summary="Liste les cours de l'utilisateur")
async def list_courses(
    instrument: str = None,
    completed: bool = None,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("courses_progress").select("*").eq("user_id", user["sub"])
    if instrument:
        query = query.eq("instrument_id", instrument)
    if completed is not None:
        query = query.eq("completed", completed)
    result = query.order("last_accessed_at", desc=True).execute()
    return {"courses": result.data}


@router.patch("/{course_id}/progress", summary="Met à jour la progression d'un cours")
async def update_progress(
    course_id: str,
    payload: dict,
    user: dict = Depends(get_current_user)
):
    """**Corps** : `{ completion_percentage: 75, completed: false }`"""
    db = get_supabase()
    db.table("courses_progress").update({
        "completion_percentage": payload.get("completion_percentage", 0),
        "completed": payload.get("completed", False),
        "last_accessed_at": "now()"
    }).eq("id", course_id).eq("user_id", user["sub"]).execute()
    return {"message": "Progression mise à jour"}
