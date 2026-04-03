from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.supabase_client import get_supabase
from services.ai_pedagogy.claude_quiz_service import generate_quiz, evaluate_answers
from services.ai_pedagogy.whisper_service import transcribe_audio_answer, evaluate_oral_answer
from fastapi import UploadFile, File

router = APIRouter(prefix="/quiz", tags=["Quiz"])


@router.post("/generate", summary="Génère un quiz adaptatif (IA Claude)")
async def generate_quiz_route(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "instrument": "piano",
      "topic": "Les intervalles musicaux",
      "level": "intermédiaire",
      "num_questions": 5,
      "analysis_id": "uuid-optionnel"
    }
    ```
    """
    user_id = user["sub"]
    db = get_supabase()

    analysis_context = None
    if payload.get("analysis_id"):
        analysis = db.table("analyses").select("detected_key,chords_sequence")\
            .eq("id", payload["analysis_id"]).eq("user_id", user_id)\
            .maybe_single().execute()
        if analysis.data:
            analysis_context = analysis.data

    quiz = await generate_quiz(
        instrument=payload.get("instrument", "guitar"),
        topic=payload.get("topic", "Théorie musicale"),
        level=payload.get("level", "débutant"),
        num_questions=payload.get("num_questions", 5),
        analysis_context=analysis_context
    )
    return quiz


@router.post("/evaluate", summary="Évalue les réponses d'un quiz")
async def evaluate_quiz(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "quiz": { ...quiz_object... },
      "answers": [
        {"question_id": 1, "answer_index": 0, "time_seconds": 12},
        {"question_id": 2, "answer_value": true, "time_seconds": 8}
      ]
    }
    ```
    """
    user_id = user["sub"]
    db = get_supabase()

    quiz = payload.get("quiz", {})
    user_answers = payload.get("answers", [])

    result = await evaluate_answers(quiz, user_answers)

    # Sauvegarder le résultat
    db.table("quiz_results").insert({
        "user_id": user_id,
        "topic": quiz.get("topic", ""),
        "instrument_id": quiz.get("instrument"),
        "level": quiz.get("level", ""),
        "score": result["total_score"],
        "total_questions": result["max_score"],
        "answers": result["results"]
    }).execute()

    return result


@router.post("/oral-answer", summary="Transcrit et évalue une réponse vocale (Whisper)")
async def evaluate_oral(
    audio: UploadFile = File(...),
    expected: str = "",
    question_type: str = "note_name",
    user: dict = Depends(get_current_user)
):
    """
    Permet les quiz oraux : l'utilisateur répond en parlant.
    Whisper transcrit la réponse, puis elle est comparée à la réponse attendue.
    """
    audio_bytes = await audio.read()

    transcription = await transcribe_audio_answer(audio_bytes, language="fr")
    if "error" in transcription:
        raise HTTPException(502, f"Erreur transcription : {transcription['error']}")

    evaluation = await evaluate_oral_answer(
        transcription=transcription["text"],
        expected_answer=expected,
        question_type=question_type
    )

    return {
        "transcription": transcription["text"],
        "evaluation": evaluation
    }


@router.get("/history", summary="Historique des quiz de l'utilisateur")
async def quiz_history(
    instrument: str = None,
    limit: int = 10,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("quiz_results").select("*").eq("user_id", user["sub"])
    if instrument:
        query = query.eq("instrument_id", instrument)
    result = query.order("created_at", desc=True).limit(limit).execute()
    return {"history": result.data}
