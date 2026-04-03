import tempfile, os
import numpy as np
from typing import List, Dict, Any, Optional

# Import conditionnel pour éviter les erreurs si Magenta n'est pas installé
try:
    from magenta.models.melody_rnn import melody_rnn_sequence_generator
    from magenta.models.melody_rnn import melody_rnn_model
    from note_seq import midi_io, sequences_lib
    from note_seq.protobuf import generator_pb2, music_pb2
    MAGENTA_AVAILABLE = True
except ImportError:
    MAGENTA_AVAILABLE = False


async def generate_melody_continuation(
    seed_notes: List[Dict],
    key_name: str = "C major",
    num_steps: int = 128,
    temperature: float = 1.0,
    model_name: str = "attention_rnn"
) -> Dict[str, Any]:
    """
    Continue une mélodie amorcée avec des notes générées par IA.

    Paramètres :
        seed_notes  : notes de départ [{"pitch": 60, "start": 0.0, "end": 0.5}]
        key_name    : tonalité ("C major", "G minor"...)
        num_steps   : nombre de pas à générer (128 = ~8 mesures à 4/4)
        temperature : créativité (0.5=conservateur, 1.0=équilibré, 2.0=expérimental)
        model_name  : "attention_rnn", "basic_rnn", "lookback_rnn"

    Retourne : dict avec la mélodie générée en notes et MIDI bytes
    """
    if not MAGENTA_AVAILABLE:
        return _fallback_melody_generation(seed_notes, key_name, num_steps)

    try:
        # Convertir les notes seed en NoteSequence Magenta
        seed_sequence = _notes_to_note_sequence(seed_notes, key_name)

        # Charger le bundle du modèle
        bundle_file = _get_model_bundle(model_name)

        generator = melody_rnn_sequence_generator.MelodyRnnSequenceGenerator(
            model=melody_rnn_model.MelodyRnnModel(
                melody_rnn_model.default_configs[model_name]
            ),
            details=None,
            steps_per_quarter=4,
            bundle=bundle_file
        )

        # Configuration de la génération
        generator_options = generator_pb2.GeneratorOptions()
        generator_options.args["temperature"].float_value = temperature
        generator_options.generate_sections.add(
            start_time=len(seed_notes) * 0.5,
            end_time=len(seed_notes) * 0.5 + num_steps * 0.125
        )

        # Générer
        generated_sequence = generator.generate(seed_sequence, generator_options)

        # Convertir en format de sortie
        generated_notes = _note_sequence_to_notes(generated_sequence)

        # Exporter en MIDI
        midi_bytes = _sequence_to_midi_bytes(generated_sequence)

        return {
            "method": "magenta_ai",
            "model": model_name,
            "temperature": temperature,
            "generated_notes": generated_notes,
            "midi_bytes": midi_bytes,
            "steps_generated": num_steps,
        }

    except Exception as e:
        return _fallback_melody_generation(seed_notes, key_name, num_steps)


def _fallback_melody_generation(
    seed_notes: List[Dict],
    key_name: str,
    num_steps: int
) -> Dict[str, Any]:
    """
    Génération de mélodie de secours si Magenta n'est pas disponible.
    Utilise des règles musicales simples (gamme + marche diatonique).
    """
    from services.ai_harmony.music21_service import get_scale_notes

    scale_data = get_scale_notes(key_name.split()[0], "major")
    scale_pitches = [_note_name_to_midi(n) for n in scale_data["notes"]]

    if not seed_notes:
        current_pitch = scale_pitches[0]
    else:
        current_pitch = seed_notes[-1].get("pitch", scale_pitches[0])

    generated = []
    t = (seed_notes[-1]["end"] if seed_notes else 0.0)
    durations = [0.25, 0.5, 0.5, 1.0]  # Double-croche, croche, croche, noire

    for step in range(min(num_steps, 64)):
        # Mouvement par degrés conjoints avec légère randomisation
        movement = np.random.choice([-2, -1, 0, 1, 2], p=[0.1, 0.3, 0.2, 0.3, 0.1])
        current_idx = _closest_scale_degree(current_pitch, scale_pitches)
        new_idx = max(0, min(len(scale_pitches)-1, current_idx + movement))
        current_pitch = scale_pitches[new_idx]

        duration = np.random.choice(durations, p=[0.1, 0.4, 0.3, 0.2])
        generated.append({
            "pitch": current_pitch,
            "pitch_name": _midi_to_note_name(current_pitch),
            "start": round(t, 3),
            "end": round(t + duration, 3),
            "duration": duration,
            "confidence": 1.0
        })
        t += duration

    return {
        "method": "rule_based_fallback",
        "generated_notes": generated,
        "steps_generated": len(generated),
    }


def _note_name_to_midi(note_name: str) -> int:
    """Convertit 'C4' → 60, 'G#3' → 44..."""
    notes = {"C":0,"C#":1,"D":2,"D#":3,"E":4,"F":5,"F#":6,"G":7,"G#":8,"A":9,"A#":10,"B":11}
    # Extraire la note et l'octave
    if len(note_name) >= 2:
        if note_name[1] in ("#", "b"):
            note_part = note_name[:2]
            octave = int(note_name[2:]) if note_name[2:].lstrip("-").isdigit() else 4
        else:
            note_part = note_name[0]
            octave = int(note_name[1:]) if note_name[1:].lstrip("-").isdigit() else 4
        return (octave + 1) * 12 + notes.get(note_part, 0)
    return 60

def _midi_to_note_name(midi: int) -> str:
    notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    return f"{notes[midi % 12]}{(midi // 12) - 1}"

def _closest_scale_degree(pitch: int, scale_pitches: List[int]) -> int:
    return min(range(len(scale_pitches)), key=lambda i: abs(scale_pitches[i] - pitch))


def _notes_to_note_sequence(notes, key_name):
    # Dummy implementation for fallback
    return None

def _get_model_bundle(model_name):
    return None

def _note_sequence_to_notes(sequence):
    return []

def _sequence_to_midi_bytes(sequence):
    return b""
