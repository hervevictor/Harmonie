from music21 import (
    stream, note, chord, key, roman, interval,
    scale as m21_scale, meter, tempo as m21_tempo,
    clef, musicxml
)
from typing import List, Dict, Any, Optional
import tempfile, os, io

# ── GAMMES SUPPORTÉES (avec protection contre les versions de music21) ──
def _get_scale_class(name: str):
    return getattr(m21_scale, name, m21_scale.MajorScale)

SCALE_TYPES = {
    "major":      _get_scale_class("MajorScale"),
    "minor":      _get_scale_class("MinorScale"),
    "harmonic_minor": _get_scale_class("HarmonicMinorScale"),
    "melodic_minor":  _get_scale_class("MelodicMinorScale"),
    "pentatonic_major": _get_scale_class("MajorPentatonicScale"),
    "pentatonic_minor": _get_scale_class("MinorPentatonicScale"),
    "blues":      _get_scale_class("BluesScale"),
    "dorian":     _get_scale_class("DorianScale"),
    "phrygian":   _get_scale_class("PhrygianScale"),
    "lydian":     _get_scale_class("LydianScale"),
    "mixolydian": _get_scale_class("MixolydianScale"),
    "locrian":    _get_scale_class("LocrianScale"),
    "whole_tone": _get_scale_class("WholeToneScale"),
    "chromatic":  _get_scale_class("ChromaticScale"),
}


def get_scale_notes(tonic: str, scale_type: str = "major") -> Dict[str, Any]:
    """
    Retourne toutes les notes d'une gamme donnée.

    Exemple :
        get_scale_notes("G", "major")
        → {"notes": ["G4", "A4", "B4", "C5", "D5", "E5", "F#5", "G5"],
           "degrees": ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]}
    """
    scale_class = SCALE_TYPES.get(scale_type, m21_scale.MajorScale)
    sc = scale_class(tonic)
    pitches = sc.getPitches()

    roman_degrees = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
    return {
        "tonic": tonic,
        "scale_type": scale_type,
        "notes": [str(p) for p in pitches],
        "note_names_only": [p.name for p in pitches],
        "degrees": roman_degrees[:len(pitches)],
        "total_notes": len(pitches)
    }


def generate_diatonic_chords(tonic: str, scale_type: str = "major") -> List[Dict[str, Any]]:
    """
    Génère les accords diatoniques (triades et septièmes) d'une gamme.

    Pour Do majeur : I(C), ii(Dm), iii(Em), IV(F), V(G), vi(Am), vii°(Bdim)
    """
    scale_class = SCALE_TYPES.get(scale_type, m21_scale.MajorScale)
    k = key.Key(tonic, scale_type if scale_type in ["major", "minor"] else "major")

    chords_list = []
    roman_numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]

    for i, degree in enumerate(roman_numerals[:7], start=1):
        try:
            rn = roman.RomanNumeral(degree, k)
            c = rn.chord

            # Accord de 7e
            rn7 = roman.RomanNumeral(f"{degree}7", k)
            c7 = rn7.chord

            chords_list.append({
                "degree": degree,
                "degree_number": i,
                "chord_name": c.commonName,
                "chord_symbol": c.root().name + ("m" if c.quality == "minor" else ""),
                "notes": [str(p) for p in c.pitches],
                "seventh_chord": c7.commonName,
                "quality": c.quality,
                "function": get_harmonic_function(i, scale_type)
            })
        except Exception:
            continue

    return chords_list


def get_harmonic_function(degree: int, scale_type: str) -> str:
    """Retourne la fonction harmonique d'un degré."""
    functions = {
        1: "tonique", 2: "sous-dominante", 3: "médiane",
        4: "sous-dominante", 5: "dominante",
        6: "sous-médiante", 7: "sensible"
    }
    return functions.get(degree, "")


def get_chords_from_notes_sequence(
    notes_sequence: List[Dict],
    key_name: str,
    window_seconds: float = 1.0
) -> List[Dict[str, Any]]:
    """
    Analyse une séquence de notes et génère les accords correspondants
    en utilisant des fenêtres temporelles.
    """
    k = key.Key(key_name.split()[0])
    chords_result = []
    current_time = 0.0

    # Regrouper les notes par fenêtre de temps
    while current_time < max((n["end"] for n in notes_sequence), default=0):
        window_notes = [
            n for n in notes_sequence
            if n["start"] < current_time + window_seconds
            and n["end"] > current_time
        ]

        if window_notes:
            pitches = [n.get("pitch_name", f"C{n.get('pitch', 60) // 12}") for n in window_notes]
            try:
                c = chord.Chord(pitches[:4])  # Max 4 notes par accord
                rn = roman.romanNumeralFromChord(c, k)
                chords_result.append({
                    "time": current_time,
                    "chord": rn.figure,
                    "chord_name": c.commonName,
                    "notes": pitches[:4],
                    "quality": c.quality if hasattr(c, 'quality') else ""
                })
            except Exception:
                pass

        current_time += window_seconds

    return chords_result


def transpose_notes(
    notes_sequence: List[Dict],
    from_key: str,
    to_key: str
) -> Dict[str, Any]:
    """
    Transpose une séquence de notes d'une tonalité vers une autre.

    Exemple : transposer de C major vers G major (montée de quinte)
    """
    from_tonic = from_key.split()[0]
    to_tonic = to_key.split()[0]

    try:
        from_note = note.Note(from_tonic)
        to_note = note.Note(to_tonic)
        ivl = interval.Interval(from_note.pitch, to_note.pitch)

        transposed = []
        for n in notes_sequence:
            try:
                n_obj = note.Note(n.get("pitch_name", "C4"))
                transposed_note = n_obj.transpose(ivl)
                transposed.append({
                    **n,
                    "pitch_name": transposed_note.nameWithOctave,
                    "pitch": transposed_note.midi,
                    "original_pitch": n.get("pitch_name", "C4")
                })
            except Exception:
                transposed.append(n)

        return {
            "from_key": from_key,
            "to_key": to_key,
            "interval": str(ivl.directedName),
            "semitones": ivl.semitones,
            "notes_sequence": transposed
        }
    except Exception as e:
        return {"error": f"Erreur transposition : {e}"}


def generate_score_musicxml(
    notes_sequence: List[Dict],
    key_name: str = "C major",
    time_sig: str = "4/4",
    tempo_bpm: float = 120.0,
    instrument_name: str = "Piano",
    title: str = "Score généré"
) -> bytes:
    """
    Génère une partition MusicXML depuis une séquence de notes.
    Le MusicXML peut être ouvert dans MuseScore, Finale, Sibelius...
    """
    # Créer la partition
    score = stream.Score()
    score.metadata.title = title
    score.metadata.composer = "Music AI"

    # Créer la partie
    part = stream.Part()
    part.partName = instrument_name

    # Ajouter la clé, la mesure et le tempo
    tonic, mode = (key_name.split() + ["major"])[:2]
    part.append(key.Key(tonic, mode))
    part.append(meter.TimeSignature(time_sig))
    part.append(m21_tempo.MetronomeMark(number=tempo_bpm))

    # Ajouter les notes
    for n_data in notes_sequence:
        pitch_name = n_data.get("pitch_name", "C4")
        duration_beats = n_data.get("duration_beats", 1.0)

        try:
            n = note.Note(pitch_name)
            n.quarterLength = duration_beats
            part.append(n)
        except Exception:
            # Note invalide → silence
            r = note.Rest()
            r.quarterLength = max(duration_beats, 0.25)
            part.append(r)

    score.append(part)

    # Sérialiser en MusicXML
    with tempfile.NamedTemporaryFile(suffix=".xml", delete=False) as tmp:
        score.write("musicxml", fp=tmp.name)
        xml_content = open(tmp.name, "rb").read()
        os.unlink(tmp.name)

    return xml_content


def suggest_chord_progression(key_name: str, style: str = "pop") -> Dict[str, Any]:
    """
    Suggère des progressions d'accords populaires dans une tonalité.

    Styles supportés : pop, jazz, blues, classical, bossa_nova, flamenco
    """
    progressions = {
        "pop": [
            {"name": "I-V-vi-IV", "chords": [1, 5, 6, 4], "example": "Let It Be"},
            {"name": "I-IV-V-I",  "chords": [1, 4, 5, 1], "example": "Stand By Me"},
            {"name": "vi-IV-I-V", "chords": [6, 4, 1, 5], "example": "Zombie"},
        ],
        "jazz": [
            {"name": "ii-V-I",    "chords": [2, 5, 1],    "example": "Autumn Leaves"},
            {"name": "I-vi-ii-V", "chords": [1, 6, 2, 5], "example": "Fly Me to the Moon"},
        ],
        "blues": [
            {"name": "12-bar blues", "chords": [1,1,1,1, 4,4,1,1, 5,4,1,5], "example": "Sweet Home Chicago"},
        ],
        "classical": [
            {"name": "I-IV-V-I",  "chords": [1, 4, 5, 1], "example": "Cadence parfaite"},
            {"name": "I-V-I",     "chords": [1, 5, 1],    "example": "Cadence authentique"},
        ],
    }

    diatonic = generate_diatonic_chords(key_name.split()[0])
    style_progressions = progressions.get(style, progressions["pop"])

    result = []
    for prog in style_progressions:
        resolved_chords = []
        for degree in prog["chords"]:
            if degree <= len(diatonic):
                resolved_chords.append(diatonic[degree - 1]["chord_symbol"])
        result.append({
            **prog,
            "resolved_chords": resolved_chords,
            "key": key_name
        })

    return {"key": key_name, "style": style, "progressions": result}
