from fastapi import Depends, HTTPException, Header
from typing import Optional
import jwt
from config import settings

async def get_current_user(authorization: str = Header(...)) -> dict:
    """
    Vérifie le JWT Supabase et retourne le payload utilisateur.
    Le token est généré côté Flutter par supabase.auth.currentSession.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Format du token invalide")

    token = authorization.replace("Bearer ", "")
    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated"
        )
        return payload

    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expiré — reconnectez-vous")
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=401, detail=f"Token invalide : {e}")


async def get_optional_user(authorization: Optional[str] = Header(None)) -> Optional[dict]:
    """Pour les routes accessibles avec ou sans authentification."""
    if not authorization:
        return None
    try:
        return await get_current_user(authorization)
    except HTTPException:
        return None
