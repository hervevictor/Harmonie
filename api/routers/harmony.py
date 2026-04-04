from fastapi import APIRouter, Depends
from core.auth import get_current_user
from services.ai_harmony.music21_service import (
    get_scale_notes, generate_diatonic_chords, suggest_chord_progression
)
from services.ai_harmony.magenta_service import generate_melody_continuation
from services.ai_pedagogy.claude_harmony_service import explain_harmony

router = APIRouter(prefix="/harmony", tags=["Harmonie"])

@router.get("/scale", summary="Obtenir les notes d'une gamme")
async def get_scale(
    tonic: str = "C",
    scale_type: str = "major",
    user: dict = Depends(get_current_user)
):
    """
    **Gammes supportées** : major, minor, harmonic_minor, melodic_minor,
    pentatonic_major, pentatonic_minor, blues, dorian, phrygian,
    lydian, mixolydian, locrian, whole_tone, chromatic
    """
    return get_scale_notes(tonic, scale_type)


@router.get("/chords", summary="Accords diatoniques d'une gamme")
async def get_diatonic_chords(
    tonic: str = "C",
    scale_type: str = "major",
    user: dict = Depends(get_current_user)
):
    return {"tonic": tonic, "scale_type": scale_type, "chords": generate_diatonic_chords(tonic, scale_type)}


@router.get("/progressions", summary="Progressions d'accords suggérées")
async def get_progressions(
    tonic: str = "C",
    scale_type: str = "major",
    style: str = "pop",
    user: dict = Depends(get_current_user)
):
    """
    **Styles** : pop, jazz, blues, classical, bossa_nova
    """
    return suggest_chord_progression(f"{tonic} {scale_type}", style)


@router.post("/explain", summary="Explique une progression harmonique (IA)")
async def explain_harmony_route(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "chords": ["Am", "F", "C", "G"],
      "key": "A minor",
      "instrument": "guitar",
      "level": "débutant"
    }
    ```
    """
    return await explain_harmony(
        chords=payload.get("chords", []),
        key_name=payload.get("key", "C major"),
        instrument=payload.get("instrument", "guitar"),
        level=payload.get("level", "débutant")
    )


@router.post("/generate-melody", summary="Génère une continuation mélodique (IA Magenta)")
async def generate_melody(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "seed_notes": [{"pitch": 60, "start": 0.0, "end": 0.5}],
      "key": "C major",
      "num_steps": 64,
      "temperature": 1.0
    }
    ```
    """
    return await generate_melody_continuation(
        seed_notes=payload.get("seed_notes", []),
        key_name=payload.get("key", "C major"),
        num_steps=payload.get("num_steps", 64),
        temperature=payload.get("temperature", 1.0)
    )


@router.post("/chat", summary="Chat avec l'assistant musical (IA)")
async def chat_with_harmony(payload: dict):
    """
    **PUBLIC** : Chat avec l'assistant musical.
    """
    from services.ai_pedagogy.claude_harmony_service import _openai, is_groq, SYSTEM_PROMPT_HARMONY
    
    messages = payload.get("messages", [])
    context = payload.get("analysisContext", "")
    
    system_prompt = SYSTEM_PROMPT_HARMONY
    if context:
        system_prompt += f"\n\nContexte musical actuel :\n{context}"
        
    full_messages = [{"role": "system", "content": system_prompt}] + messages
    
    model = "llama-3.3-70b-versatile" if is_groq else "gpt-4o"
    
    try:
        response = await _openai.chat.completions.create(
            model=model,
            messages=full_messages,
            max_tokens=2000
        )
        return {"content": response.choices[0].message.content}
    except Exception as e:
        return {"error": str(e), "content": "Désolé, je ne peux pas répondre pour le moment."}
