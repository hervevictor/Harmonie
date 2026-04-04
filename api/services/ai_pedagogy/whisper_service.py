import httpx, tempfile, os
from typing import Dict, Any
from config import settings

async def transcribe_audio_answer(
    audio_bytes: bytes,
    language: str = "fr",
    prompt: str = ""
) -> Dict[str, Any]:
    """
    Transcrit une réponse audio pour un quiz oral.

    Paramètres :
        audio_bytes : enregistrement audio de la réponse (WAV ou MP3)
        language    : langue de transcription ("fr", "en"...)
        prompt      : contexte pour améliorer la précision (ex: "noms de notes de musique")

    Retourne :
        {"text": "Do dièse", "confidence": 0.95, "language": "fr"}
    """
    is_groq = settings.OPENAI_API_KEY.startswith("gsk_")
    url = "https://api.groq.com/openai/v1/audio/transcriptions" if is_groq else "https://api.openai.com/v1/audio/transcriptions"
    model = "whisper-large-v3" if is_groq else "whisper-1"

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            url,
            headers={"Authorization": f"Bearer {settings.OPENAI_API_KEY}"},
            files={"file": ("answer.wav", audio_bytes, "audio/wav")},
            data={
                "model": model,
                "language": language,
                "prompt": prompt or "Noms de notes musicales, accords, termes musicaux en français",
                "response_format": "verbose_json",
                "temperature": 0.0  # Déterministe pour meilleure précision
            }
        )

    if response.status_code != 200:
        return {"error": f"Erreur Whisper : {response.text}", "text": ""}

    data = response.json()
    return {
        "text": data.get("text", "").strip(),
        "language": data.get("language", language),
        "duration_seconds": data.get("duration", 0),
        "segments": [
            {"text": seg["text"], "confidence": seg.get("avg_logprob", 0)}
            for seg in data.get("segments", [])
        ]
    }


async def evaluate_oral_answer(
    transcription: str,
    expected_answer: str,
    question_type: str = "note_name"
) -> Dict[str, Any]:
    """
    Compare la transcription de la réponse orale avec la réponse attendue.

    Types : "note_name", "chord_name", "interval", "free_answer"
    """
    text = transcription.lower().strip()
    expected = expected_answer.lower().strip()

    # Normalisation des termes musicaux français
    aliases = {
        "do": ["c", "do"],
        "ré": ["d", "re", "ré"],
        "mi": ["e", "mi"],
        "fa": ["f", "fa"],
        "sol": ["g", "sol"],
        "la": ["a", "la"],
        "si": ["b", "si"],
        "dièse": ["sharp", "#", "dièse", "diese"],
        "bémol": ["flat", "b", "bémol", "bemol"],
    }

    # Vérification exacte ou par alias
    is_correct = text == expected
    if not is_correct:
        for canonical, alias_list in aliases.items():
            if expected in alias_list and text in alias_list:
                is_correct = True
                break

    return {
        "transcription": transcription,
        "expected": expected_answer,
        "is_correct": is_correct,
        "similarity_score": _text_similarity(text, expected),
        "normalized_answer": text
    }


def _text_similarity(a: str, b: str) -> float:
    """Score de similarité simple entre deux chaînes (0.0 à 1.0)."""
    if a == b:
        return 1.0
    if not a or not b:
        return 0.0
    matches = sum(c in b for c in a)
    return round(matches / max(len(a), len(b)), 2)
