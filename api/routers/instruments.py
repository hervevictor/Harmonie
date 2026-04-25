from fastapi import APIRouter, Depends, Query
from typing import Optional

router = APIRouter(prefix="/api/instruments", tags=["🎸 Instruments"])

@router.get("/voicings", summary="Liste tous les voicings disponibles par instrument")
async def list_voicings():
    """Retourne les configurations de voicing pour chaque instrument supporté."""
    from core.voicings import INSTRUMENT_VOICINGS, get_voicing_info
    
    voicings = {}
    for instrument_id in INSTRUMENT_VOICINGS:
        voicings[instrument_id] = get_voicing_info(instrument_id)
    
    return {"voicings": voicings}

@router.get("/voicings/{instrument_id}", summary="Voicing d'un instrument spécifique")
async def get_instrument_voicing(instrument_id: str):
    """Retourne la configuration de voicing pour un instrument donné."""
    from core.voicings import get_voicing_info
    
    info = get_voicing_info(instrument_id)
    if "error" in info:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail=info["error"])
    
    return info

@router.get("/voicings/{instrument_id}/chord", summary="Calculer le voicing d'un accord")
async def get_chord_voicing(
    instrument_id: str,
    chord: str = Query(..., description="Nom de l'accord (ex: Am7, C, F#m, Gmaj7)"),
):
    """Calcule les notes MIDI d'un accord avec le voicing adapté à l'instrument."""
    from core.voicings import get_chord_midi_notes, get_voicing_info, parse_chord_name
    
    info = get_voicing_info(instrument_id)
    if "error" in info:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail=info["error"])
    
    root, quality = parse_chord_name(chord)
    midi_notes = get_chord_midi_notes(chord, instrument_id)
    
    # Convertir MIDI en noms de notes pour lisibilité
    note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    named_notes = [f"{note_names[m % 12]}{(m // 12) - 1}" for m in midi_notes]
    
    return {
        "chord": chord,
        "root": root,
        "quality": quality or "major",
        "instrument": instrument_id,
        "midi_notes": midi_notes,
        "note_names": named_notes,
        "voicing_info": info,
    }
