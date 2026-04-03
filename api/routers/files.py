from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from core.auth import get_current_user
from core.supabase_client import get_supabase
from core.storage import upload_to_storage
from core.exceptions import PlanPermissionError
import uuid, mimetypes

router = APIRouter(prefix="/files", tags=["Fichiers"])

ALLOWED_TYPES = {
    "audio": ["audio/mpeg", "audio/wav", "audio/flac", "audio/ogg", "audio/mp4", "audio/aac"],
    "video": ["video/mp4", "video/quicktime", "video/webm", "video/avi"],
    "image": ["image/jpeg", "image/png", "image/webp", "image/tiff"],
    "pdf":   ["application/pdf"],
}
EXTENSION_MAP = {
    "audio/mpeg": ".mp3", "audio/wav": ".wav", "audio/flac": ".flac",
    "video/mp4": ".mp4", "image/jpeg": ".jpg", "image/png": ".png",
    "application/pdf": ".pdf"
}


@router.post("/upload", summary="Upload un fichier musical")
async def upload_file(
    file: UploadFile = File(...),
    user: dict = Depends(get_current_user)
):
    """
    Upload un fichier audio, vidéo, image ou PDF vers Supabase Storage.
    Vérifie les permissions selon le plan de l'utilisateur.

    **Entrée** : Multipart file
    **Sortie** : `{ file_id, status, file_type, size_bytes }`
    """
    user_id = user["sub"]
    content = await file.read()
    mime = file.content_type or mimetypes.guess_type(file.filename)[0] or ""

    # Déterminer le type de fichier
    file_type = next((k for k, mimes in ALLOWED_TYPES.items() if mime in mimes), None)
    if not file_type:
        raise HTTPException(400, f"Type non supporté : {mime}. Acceptés : audio, vidéo, image, PDF")

    # Vérifier la taille
    db = get_supabase()
    plan = await _get_user_plan(user_id, db)
    max_size = plan.get("max_file_size_mb", 25) * 1024 * 1024
    if len(content) > max_size:
        raise HTTPException(413, f"Fichier trop volumineux. Max : {plan['max_file_size_mb']}MB")

    # Vérifier les permissions de type
    if file_type == "video" and not plan.get("can_upload_video"):
        raise PlanPermissionError("upload de vidéos")
    if file_type == "pdf" and not plan.get("can_upload_pdf"):
        raise PlanPermissionError("upload de PDF")

    # Upload Storage
    ext = EXTENSION_MAP.get(mime, "")
    storage_path = f"{user_id}/{uuid.uuid4()}{ext}"
    await upload_to_storage("music-files", storage_path, content, mime)

    # Enregistrer en base
    record = db.table("files").insert({
        "user_id": user_id,
        "original_name": file.filename,
        "storage_path": storage_path,
        "file_type": file_type,
        "mime_type": mime,
        "size_bytes": len(content),
        "status": "ready"
    }).execute()

    # Logger l'action
    db.table("usage_logs").insert({
        "user_id": user_id,
        "action": "file_upload",
        "metadata": {"file_type": file_type, "size_bytes": len(content)}
    }).execute()

    return {
        "file_id": record.data[0]["id"],
        "status": "ready",
        "file_type": file_type,
        "size_bytes": len(content),
        "original_name": file.filename
    }


@router.get("/", summary="Liste les fichiers de l'utilisateur")
async def list_files(
    file_type: str = None,
    limit: int = 20,
    offset: int = 0,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("files").select("*").eq("user_id", user["sub"])
    if file_type:
        query = query.eq("file_type", file_type)
    result = query.order("uploaded_at", desc=True).range(offset, offset + limit - 1).execute()
    return {"files": result.data, "total": len(result.data)}


@router.delete("/{file_id}", summary="Supprime un fichier")
async def delete_file(file_id: str, user: dict = Depends(get_current_user)):
    db = get_supabase()
    record = db.table("files").select("*").eq("id", file_id).eq("user_id", user["sub"]).single().execute()
    if not record.data:
        raise HTTPException(404, "Fichier introuvable")
    from core.storage import delete_from_storage
    await delete_from_storage("music-files", record.data["storage_path"])
    db.table("files").delete().eq("id", file_id).execute()
    return {"message": "Fichier supprimé"}


async def _get_user_plan(user_id: str, db) -> dict:
    sub = db.table("subscriptions").select(
        "plans(max_file_size_mb, can_upload_video, can_upload_pdf, max_uploads_per_month)"
    ).eq("user_id", user_id).eq("status", "active").maybe_single().execute()
    return sub.data["plans"] if sub.data else {
        "max_file_size_mb": 10, "can_upload_video": False, "can_upload_pdf": False
    }
