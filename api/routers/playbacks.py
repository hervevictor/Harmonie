from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.supabase_client import get_supabase

router = APIRouter(prefix="/playbacks", tags=["▶️ Playback"])

@router.get("/", summary="Historique d'écoute de l'utilisateur")
async def list_playbacks(limit: int = 10, user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("playbacks").select("*, analyses(*)").eq("user_id", user["sub"]).order("played_at", desc=True).limit(limit).execute()
    return {"playbacks": result.data}

@router.post("/", summary="Enregistre un événement de lecture")
async def create_playback(payload: dict, user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("playbacks").insert({
        "user_id": user["sub"],
        "analysis_id": payload.get("analysis_id"),
        "instrument_id": payload.get("instrument_id")
    }).execute()
    return result.data[0]
