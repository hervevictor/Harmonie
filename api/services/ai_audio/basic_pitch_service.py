import tempfile, os
from typing import List, Dict, Any
from basic_pitch.inference import predict, Model
from basic_pitch import ICASSP_2022_MODEL_PATH
import numpy as np

# Charger le modèle une seule fois au démarrage (lourd à charger)
_model: Model | None = None

def get_basic_pitch_model() -> Model:
    global _model
    if _model is None:
        _model = Model(ICASSP_2022_MODEL_PATH)
    return _model


async def transcribe_audio_to_notes(file_bytes: bytes, file_extension: str = ".wav") -> Dict[str, Any]:
    """
    Transcrit un fichier audio en séquence de notes musicales.

    Paramètres :
        file_bytes    : contenu du fichier audio en bytes
        file_extension: extension du fichier (.mp3, .wav, .flac...)

    Retourne :
        {
          "notes_sequence": [{"pitch": int, "start": float, "end": float, "confidence": float}],
          "midi_data"     : pretty_midi.PrettyMIDI object,
          "piano_roll"    : np.ndarray (pitch × time),
          "note_events"   : liste brute des événements
        }
    """
    with tempfile.NamedTemporaryFile(suffix=file_extension, delete=False) as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name

    try:
        model = get_basic_pitch_model()

        # Prédiction : retourne (model_output, midi_data, note_events)
        model_output, midi_data, note_events = predict(
            audio_path=tmp_path,
            model_or_model_path=model,
            onset_threshold=0.5,       # seuil de détection d'attaque (0-1)
            frame_threshold=0.3,       # seuil de présence de note (0-1)
            minimum_note_length=58,    # durée minimale en millisecondes
            minimum_frequency=None,    # fréquence minimale (None = pas de limite)
            maximum_frequency=None,    # fréquence maximale
            multiple_pitch_bends=False,# un pitch bend par note
            melodia_trick=True,        # améliore la détection de mélodie principale
        )

        # Construire la séquence de notes structurée
        notes_sequence = []
        for event in note_events:
            start_time, end_time, pitch_midi, amplitude, pitch_bends = event
            notes_sequence.append({
                "pitch": int(pitch_midi),           # numéro MIDI (0-127)
                "pitch_name": midi_to_note_name(pitch_midi),  # ex: "C4", "G#3"
                "start": float(start_time),          # en secondes
                "end": float(end_time),
                "duration": float(end_time - start_time),
                "confidence": float(amplitude),      # vélocité/amplitude (0-1)
            })

        # Trier par temps de début
        notes_sequence.sort(key=lambda x: x["start"])

        return {
            "notes_sequence": notes_sequence,
            "midi_data": midi_data,
            "note_count": len(notes_sequence),
        }

    finally:
        os.unlink(tmp_path)


def midi_to_note_name(midi_number: int) -> str:
    """Convertit un numéro MIDI en nom de note (ex: 60 → 'C4')."""
    notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    octave = (midi_number // 12) - 1
    note = notes[midi_number % 12]
    return f"{note}{octave}"


async def save_midi_to_bytes(midi_data) -> bytes:
    """Sérialise un objet PrettyMIDI en bytes pour stockage."""
    with tempfile.NamedTemporaryFile(suffix=".mid", delete=False) as tmp:
        midi_data.write(tmp.name)
        tmp.seek(0)
        return open(tmp.name, "rb").read()
