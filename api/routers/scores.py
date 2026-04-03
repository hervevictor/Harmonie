from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.supabase_client import get_supabase

router = APIRouter(prefix="/scores", tags=["📄 Partitions"])

@router.get("/", summary="Liste les partitions générées")
async def list_scores(user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("generated_scores").select("*, analyses(*)").eq("user_id", user["sub"]).execute()
    return {"scores": result.data}

@router.post("/", summary="Enregistre une nouvelle partition générée")
async def create_score(payload: dict, user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("generated_scores").insert({
        "user_id": user["sub"],
        "analysis_id": payload.get("analysis_id"),
        "target_key": payload.get("target_key"),
        "format": payload.get("format", "pdf"),
        "storage_path": payload.get("storage_path")
    }).execute()
    return result.data[0]
