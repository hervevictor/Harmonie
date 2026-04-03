from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.supabase_client import get_supabase

router = APIRouter(prefix="/subscriptions", tags=["💳 Abonnements"])

@router.get("/me", summary="Plan actif de l'utilisateur")
async def get_my_subscription(user: dict = Depends(get_current_user)):
    db = get_supabase()
    sub = db.table("subscriptions").select("*, plans(*)").eq("user_id", user["sub"]).eq("status", "active").maybe_single().execute()
    return {"subscription": sub.data}

@router.get("/plans", summary="Liste tous les plans disponibles")
async def list_plans(user: dict = Depends(get_current_user)):
    db = get_supabase()
    plans = db.table("plans").select("*").execute()
    return {"plans": plans.data}
