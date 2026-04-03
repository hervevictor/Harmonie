from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.supabase_client import get_supabase

router = APIRouter(prefix="/instruments", tags=["🎸 Instruments"])

@router.get("/", summary="Liste tous les instruments disponibles")
async def list_instruments(user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("instruments").select("*").execute()
    return {"instruments": result.data}

@router.get("/{instrument_id}", summary="Détails d'un instrument")
async def get_instrument(instrument_id: str, user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("instruments").select("*").eq("id", instrument_id).single().execute()
    return result.data
