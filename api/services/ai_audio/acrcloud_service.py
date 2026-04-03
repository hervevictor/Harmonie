import hashlib, hmac, base64, time, httpx
from config import settings
from typing import Dict, Any, Optional

async def identify_song(file_bytes: bytes, file_format: str = "mp3") -> Dict[str, Any]:
    """
    Identifie une chanson via ACRCloud.
    Fonctionne avec un extrait de 10-30 secondes minimum.

    Retourne :
        {
          "title"    : "Nom de la chanson",
          "artist"   : "Nom de l'artiste",
          "album"    : "Nom de l'album",
          "release_date": "2023-01-15",
          "isrc"     : "USRC11600947",
          "duration_ms": 245000,
          "score"    : 100,            # score de confiance (0-100)
          "found"    : True/False
        }
    """
    # Construction de la signature HMAC-SHA1
    http_method = "POST"
    http_uri = "/v1/identify"
    access_key = settings.ACRCLOUD_ACCESS_KEY
    secret_key = settings.ACRCLOUD_SECRET_KEY
    data_type = "audio"
    signature_version = "1"
    timestamp = str(int(time.time()))

    string_to_sign = "\n".join([
        http_method, http_uri, access_key,
        data_type, signature_version, timestamp
    ])

    signature = base64.b64encode(
        hmac.new(
            secret_key.encode("utf-8"),
            string_to_sign.encode("utf-8"),
            digestmod=hashlib.sha1
        ).digest()
    ).decode("utf-8")

    # Prendre les 30 premières secondes si le fichier est plus long
    sample_bytes = file_bytes[:1024 * 1024]  # max 1MB

    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.post(
            f"https://{settings.ACRCLOUD_HOST}/v1/identify",
            data={
                "access_key": access_key,
                "sample_bytes": len(sample_bytes),
                "timestamp": timestamp,
                "signature": signature,
                "data_type": data_type,
                "signature_version": signature_version,
            },
            files={"sample": ("audio.mp3", sample_bytes, f"audio/{file_format}")}
        )

    data = response.json()
    status_code = data.get("status", {}).get("code", -1)

    if status_code == 0:
        # Chanson trouvée
        music = data["metadata"]["music"][0]
        return {
            "found": True,
            "title": music.get("title", ""),
            "artist": ", ".join([a["name"] for a in music.get("artists", [])]),
            "album": music.get("album", {}).get("name", ""),
            "release_date": music.get("release_date", ""),
            "isrc": music.get("external_ids", {}).get("isrc", ""),
            "duration_ms": music.get("duration_ms", 0),
            "score": music.get("score", 0),
            "genres": [g["name"] for g in music.get("genres", [])],
            "label": music.get("label", ""),
        }
    elif status_code == 1001:
        return {"found": False, "reason": "Chanson non reconnue dans la base ACRCloud"}
    else:
        return {"found": False, "reason": data.get("status", {}).get("msg", "Erreur inconnue")}
