from config import settings
from core.supabase_client import get_supabase
from fastapi import HTTPException

async def upload_to_storage(bucket: str, path: str, data: bytes, content_type: str) -> str:
    """Upload un fichier dans Supabase Storage. Retourne le chemin public."""
    db = get_supabase()
    try:
        db.storage.from_(bucket).upload(
            path=path,
            file=data,
            file_options={"content-type": content_type, "upsert": "true"}
        )
        public_url = db.storage.from_(bucket).get_public_url(path)
        return public_url
    except Exception as e:
        raise HTTPException(500, f"Erreur upload Storage : {e}")


async def download_from_storage(bucket: str, path: str) -> bytes:
    """Télécharge un fichier depuis Supabase Storage."""
    db = get_supabase()
    try:
        response = db.storage.from_(bucket).download(path)
        return response
    except Exception as e:
        raise HTTPException(500, f"Erreur download Storage : {e}")


async def delete_from_storage(bucket: str, path: str) -> None:
    """Supprime un fichier du Storage."""
    db = get_supabase()
    db.storage.from_(bucket).remove([path])
