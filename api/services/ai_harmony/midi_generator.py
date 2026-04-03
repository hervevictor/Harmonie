from services.ai_audio.basic_pitch_service import save_midi_to_bytes
import pretty_midi

async def generate_midi_from_notes(notes: list, tempo_bpm: float = 120.0) -> bytes:
    """Génère un fichier MIDI à partir d'une liste de notes."""
    pm = pretty_midi.PrettyMIDI(initial_tempo=tempo_bpm)
    instrument = pretty_midi.Instrument(program=0) # Piano

    for n in notes:
        note = pretty_midi.Note(
            velocity=int(n.get("confidence", 0.8) * 127),
            pitch=int(n["pitch"]),
            start=float(n["start"]),
            end=float(n["end"])
        )
        instrument.notes.append(note)

    pm.instruments.append(instrument)
    return await save_midi_to_bytes(pm)
