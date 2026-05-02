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
    return suggest_chord_progression(f"{tonic} {scale_type}", style)


@router.post("/explain", summary="Explique une progression harmonique (IA)")
async def explain_harmony_route(payload: dict, user: dict = Depends(get_current_user)):
    return await explain_harmony(
        chords=payload.get("chords", []),
        key_name=payload.get("key", "C major"),
        instrument=payload.get("instrument", "guitar"),
        level=payload.get("level", "débutant")
    )


@router.post("/generate-melody", summary="Génère une continuation mélodique (IA Magenta)")
async def generate_melody(payload: dict, user: dict = Depends(get_current_user)):
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
    from services.ai_pedagogy.claude_harmony_service import _openai, is_groq
    
    # SYSTEM PROMPT HYPER-STRICT
    SYSTEM_PROMPT_CHAT = """Tu es Harmonie, un assistant musical expert et chaleureux. 
Tu réponds TOUJOURS en français simple, convivial et bien structuré.
IMPORTANT : 
- NE RÉPONDS JAMAIS EN FORMAT JSON (pas d'accolades {} ni de guillemets autour du texte).
- ÉCRIS COMME UN HUMAIN QUI PARLE.
- Utilise le Markdown pour le gras (**texte**) et les listes.

IMAGES :
Si on te demande une image, une partition ou une illustration, insère cette URL à la fin :
https://pollinations.ai/p/[description_courte_anglais]?width=800&height=600&nologo=true
"""
    
    messages = payload.get("messages", [])
    context = payload.get("analysisContext", "")
    
    system_prompt = SYSTEM_PROMPT_CHAT
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
        content = response.choices[0].message.content
        
        # Nettoyage ultime si l'IA persiste à mettre du JSON (cas rare)
        if content.startswith('{') and content.endswith('}'):
            try:
                import json
                js = json.loads(content)
                content = js.get("content", js.get("message", js.get("explanation", content)))
            except:
                pass
                
        return {"content": content}
    except Exception as e:
        return {"content": "Désolé, je ne peux pas répondre pour le moment. Vérifie ma connexion."}
