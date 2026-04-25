"""
VOICINGS D'ACCORDS PAR INSTRUMENT
==================================
Définit comment chaque instrument joue les accords :
- Registre (octave de base)
- Nombre de voix simultanées
- Renversements courants
- Patterns rythmiques typiques
- Règles de conduite des voix

Basé sur les principes d'orchestration classique et jazz.
"""

from dataclasses import dataclass, field
from typing import List, Optional, Dict

# --- Intervalles de base des accords ---
CHORD_INTERVALS = {
    # Triades
    "":     [0, 4, 7],         # Majeur (C = C E G)
    "m":    [0, 3, 7],         # Mineur (Cm = C Eb G)
    "dim":  [0, 3, 6],         # Diminué
    "aug":  [0, 4, 8],         # Augmenté
    "5":    [0, 7],             # Power chord (quinte)
    "sus2": [0, 2, 7],         # Suspendu 2
    "sus4": [0, 5, 7],         # Suspendu 4

    # Septièmes
    "7":    [0, 4, 7, 10],     # Dominante 7 (C7 = C E G Bb)
    "m7":   [0, 3, 7, 10],     # Mineur 7 (Cm7 = C Eb G Bb)
    "maj7": [0, 4, 7, 11],     # Majeur 7 (Cmaj7 = C E G B)
    "dim7": [0, 3, 6, 9],      # Diminué 7
    "m7b5": [0, 3, 6, 10],     # Demi-diminué

    # Extensions
    "9":    [0, 4, 7, 10, 14], # Dominante 9
    "m9":   [0, 3, 7, 10, 14], # Mineur 9
    "6":    [0, 4, 7, 9],      # Sixte majeure
    "m6":   [0, 3, 7, 9],      # Sixte mineure
}

# Mapping note name -> MIDI offset (C=0)
NOTE_TO_MIDI = {
    "C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3,
    "E": 4, "Fb": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7,
    "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11, "Cb": 11,
}


@dataclass
class InstrumentVoicing:
    """Configuration de voicing pour un instrument."""
    name: str
    midi_range: tuple  # (note MIDI la plus basse, note MIDI la plus haute)
    base_octave: int   # Octave de référence pour la fondamentale
    max_voices: int    # Nombre max de notes simultanées
    
    # Règles de voicing
    prefer_close_voicing: bool = True   # Voicing serré (notes proches)
    allow_doubling: bool = False        # Doubler la fondamentale ?
    bass_note_separate: bool = False    # Basse séparée (main gauche piano)
    
    # Patterns rythmiques typiques (en quarter lengths)
    # Ex: [1,1,1,1] = 4 noires, [2,2] = 2 blanches, [0.5]*8 = 8 croches
    rhythm_patterns: list = field(default_factory=lambda: [[1, 1, 1, 1]])
    
    # Renversements préférés (0 = fondamental, 1 = 1er renversement, etc.)
    preferred_inversions: list = field(default_factory=lambda: [0, 1])
    
    # Strumming pattern pour cordes (None pour les autres)
    strum_pattern: Optional[list] = None
    
    # Espacement minimum entre les voix (en demi-tons)
    min_voice_spacing: int = 1
    max_voice_spacing: int = 12


# --- Catalogue de voicings par instrument ---

INSTRUMENT_VOICINGS: Dict[str, InstrumentVoicing] = {
    "piano": InstrumentVoicing(
        name="Piano",
        midi_range=(21, 108),  # A0 → C8 (88 touches)
        base_octave=4,
        max_voices=6,
        prefer_close_voicing=True,
        allow_doubling=True,
        bass_note_separate=True,  # Main gauche = basse, main droite = accord
        rhythm_patterns=[
            [1, 1, 1, 1],      # Noires (ballade)
            [0.5] * 8,          # Croches (accompagnement pop)
            [2, 2],             # Blanches (lent)
            [1.5, 0.5, 1, 1],  # Pattern syncopé
        ],
        preferred_inversions=[0, 1, 2],
        min_voice_spacing=1,
        max_voice_spacing=16,
    ),

    "guitar_acoustic": InstrumentVoicing(
        name="Guitare acoustique",
        midi_range=(40, 88),  # E2 → E6
        base_octave=3,
        max_voices=6,  # 6 cordes
        prefer_close_voicing=True,
        allow_doubling=True,  # Fondamentale souvent doublée
        bass_note_separate=False,
        rhythm_patterns=[
            [1, 1, 1, 1],          # Strumming en noires
            [0.5] * 8,              # Picking en croches
            [0.5, 0.5, 1, 0.5, 0.5], # Pattern folk
        ],
        preferred_inversions=[0, 1],
        strum_pattern=["down", "down", "up", "down", "up", "down", "up", "down"],
        min_voice_spacing=1,
        max_voice_spacing=7,  # Limité par l'écartement des doigts
    ),

    "guitar_electric": InstrumentVoicing(
        name="Guitare électrique",
        midi_range=(40, 88),
        base_octave=3,
        max_voices=6,
        prefer_close_voicing=True,
        allow_doubling=True,
        rhythm_patterns=[
            [0.5] * 8,              # Power chords en croches
            [1, 1, 1, 1],           # Rock en noires
            [0.25] * 16,            # Metal en doubles croches
        ],
        preferred_inversions=[0],
        strum_pattern=["down", "down", "up", "down"],
        min_voice_spacing=1,
        max_voice_spacing=7,
    ),

    "violin": InstrumentVoicing(
        name="Violon",
        midi_range=(55, 103),  # G3 → G7
        base_octave=4,
        max_voices=2,  # Double cordes max en pratique
        prefer_close_voicing=True,
        allow_doubling=False,
        rhythm_patterns=[
            [2, 2],             # Blanches (legato)
            [1, 1, 1, 1],      # Noires
        ],
        preferred_inversions=[0, 1],
        min_voice_spacing=5,  # Quarte min pour double cordes
        max_voice_spacing=12,
    ),

    "flute": InstrumentVoicing(
        name="Flûte traversière",
        midi_range=(60, 96),  # C4 → C7
        base_octave=5,
        max_voices=1,  # Instrument monophonique
        prefer_close_voicing=True,
        rhythm_patterns=[
            [1, 1, 1, 1],
            [0.5] * 8,         # Ornements rapides
            [2, 1, 1],
        ],
        preferred_inversions=[0],
    ),

    "saxophone": InstrumentVoicing(
        name="Saxophone",
        midi_range=(56, 87),  # Ab3 → Eb6 (ténor)
        base_octave=4,
        max_voices=1,  # Monophonique
        rhythm_patterns=[
            [1, 0.5, 0.5, 1, 1],  # Pattern jazz swing
            [1, 1, 1, 1],
            [0.5] * 8,
        ],
        preferred_inversions=[0],
    ),

    "trumpet": InstrumentVoicing(
        name="Trompette",
        midi_range=(55, 82),  # G3 → Bb5
        base_octave=4,
        max_voices=1,
        rhythm_patterns=[
            [1, 1, 2],            # Fanfare
            [1, 1, 1, 1],
            [0.5, 0.5, 1, 1, 1],
        ],
        preferred_inversions=[0],
    ),

    "bass": InstrumentVoicing(
        name="Guitare basse",
        midi_range=(28, 67),  # E1 → G4
        base_octave=2,
        max_voices=1,  # Walking bass = une note à la fois
        prefer_close_voicing=True,
        rhythm_patterns=[
            [1, 1, 1, 1],          # Walking bass en noires
            [0.5, 0.5, 1, 0.5, 0.5, 1], # Funk/groove
            [2, 2],                 # Reggae/dub
        ],
        preferred_inversions=[0],  # Toujours la fondamentale
    ),

    "cello": InstrumentVoicing(
        name="Violoncelle",
        midi_range=(36, 76),  # C2 → E5
        base_octave=3,
        max_voices=2,  # Double cordes
        prefer_close_voicing=True,
        rhythm_patterns=[
            [2, 2],
            [4],                # Ronde (sustain)
            [1, 1, 1, 1],
        ],
        preferred_inversions=[0, 1],
        min_voice_spacing=5,
        max_voice_spacing=12,
    ),

    "ukulele": InstrumentVoicing(
        name="Ukulélé",
        midi_range=(60, 84),  # C4 → C6
        base_octave=4,
        max_voices=4,  # 4 cordes
        prefer_close_voicing=True,
        allow_doubling=False,
        rhythm_patterns=[
            [0.5] * 8,             # Strumming rapide
            [1, 0.5, 0.5, 1, 1],   # Island pattern
        ],
        preferred_inversions=[0, 1],
        strum_pattern=["down", "down", "up", "up", "down", "up"],
        min_voice_spacing=1,
        max_voice_spacing=5,
    ),

    "harmonica": InstrumentVoicing(
        name="Harmonica",
        midi_range=(60, 96),  # C4 → C7 (diatonique en C)
        base_octave=4,
        max_voices=3,  # Peut jouer des accords simples
        prefer_close_voicing=True,
        rhythm_patterns=[
            [1, 1, 1, 1],
            [0.5, 0.5, 1, 0.5, 0.5, 1],  # Blues
        ],
        preferred_inversions=[0],
        min_voice_spacing=1,
        max_voice_spacing=7,
    ),
}


def parse_chord_name(chord_str: str) -> tuple:
    """
    Parse un nom d'accord en (root, quality).
    Ex: 'Am7' → ('A', 'm7'), 'C' → ('C', ''), 'F#m' → ('F#', 'm')
    Gère aussi les noms complets comme 'C Major' -> ('C', '')
    """
    chord_str = chord_str.strip()
    if not chord_str:
        return ("C", "")
    
    # Nettoyage des mots complets
    chord_str = chord_str.replace("Major", "").replace("major", "").strip()
    if "Minor" in chord_str or "minor" in chord_str:
        chord_str = chord_str.replace("Minor", "m").replace("minor", "m").strip()

    # Extraire la racine (1 ou 2 caractères)
    if len(chord_str) >= 2 and chord_str[1] in ('#', 'b'):
        root = chord_str[:2]
        quality = chord_str[2:]
    else:
        root = chord_str[0]
        quality = chord_str[1:]
    
    return (root, quality)


def get_chord_midi_notes(chord_str: str, instrument_id: str = "piano") -> List[int]:
    """
    Génère les notes MIDI d'un accord pour un instrument donné.
    Applique les règles de voicing spécifiques à l'instrument.
    
    Returns: Liste de notes MIDI triées.
    """
    root, quality = parse_chord_name(chord_str)
    voicing = INSTRUMENT_VOICINGS.get(instrument_id, INSTRUMENT_VOICINGS["piano"])
    
    # Note MIDI de la fondamentale dans l'octave de base
    root_offset = NOTE_TO_MIDI.get(root, 0)
    root_midi = root_offset + (voicing.base_octave + 1) * 12  # MIDI: C4 = 60
    
    # Récupérer les intervalles de l'accord
    intervals = CHORD_INTERVALS.get(quality, CHORD_INTERVALS.get("", [0, 4, 7]))
    
    # Construire les notes de base
    base_notes = [root_midi + interval for interval in intervals]
    
    # Appliquer les règles de l'instrument
    result_notes = []
    
    if voicing.max_voices == 1:
        # Instrument monophonique → jouer seulement la fondamentale (ou arpège séquentiel)
        result_notes = [root_midi]
    
    elif voicing.bass_note_separate:
        # Piano : basse séparée (main gauche octave en dessous)
        bass_note = root_midi - 12
        if bass_note >= voicing.midi_range[0]:
            result_notes.append(bass_note)
        # Main droite : accord
        for note in base_notes[:voicing.max_voices - 1]:
            if voicing.midi_range[0] <= note <= voicing.midi_range[1]:
                result_notes.append(note)
        # Doubler la fondamentale à l'octave si possible
        if voicing.allow_doubling and len(result_notes) < voicing.max_voices:
            doubled = root_midi + 12
            if doubled <= voicing.midi_range[1]:
                result_notes.append(doubled)
    
    else:
        # Autres instruments : voicing dans le registre de l'instrument
        for note in base_notes:
            # S'assurer que la note est dans le registre
            while note < voicing.midi_range[0]:
                note += 12
            while note > voicing.midi_range[1]:
                note -= 12
            if note not in result_notes and len(result_notes) < voicing.max_voices:
                result_notes.append(note)
        
        # Doubler si nécessaire (guitare)
        if voicing.allow_doubling and len(result_notes) < voicing.max_voices:
            for note in base_notes[:2]:
                doubled = note + 12
                if voicing.midi_range[0] <= doubled <= voicing.midi_range[1] and doubled not in result_notes:
                    result_notes.append(doubled)
                    if len(result_notes) >= voicing.max_voices:
                        break
    
    # Vérifier l'espacement entre les voix
    result_notes.sort()
    
    return result_notes


def get_rhythm_pattern(instrument_id: str, style: str = "default") -> List[float]:
    """
    Retourne un pattern rythmique adapté à l'instrument et au style.
    Les valeurs sont en quarter lengths (1 = noire, 0.5 = croche, etc.)
    """
    voicing = INSTRUMENT_VOICINGS.get(instrument_id, INSTRUMENT_VOICINGS["piano"])
    
    style_map = {
        "default": 0,
        "ballad": 0,
        "fast": 1,
        "slow": -1,
    }
    
    idx = style_map.get(style, 0) % len(voicing.rhythm_patterns)
    return voicing.rhythm_patterns[idx]


def get_voicing_info(instrument_id: str) -> dict:
    """Retourne les informations de voicing pour le frontend."""
    voicing = INSTRUMENT_VOICINGS.get(instrument_id)
    if not voicing:
        return {"error": f"Instrument '{instrument_id}' non trouvé"}
    
    return {
        "name": voicing.name,
        "midi_range": list(voicing.midi_range),
        "max_voices": voicing.max_voices,
        "base_octave": voicing.base_octave,
        "is_monophonic": voicing.max_voices == 1,
        "has_strum": voicing.strum_pattern is not None,
        "rhythm_patterns_count": len(voicing.rhythm_patterns),
        "available_inversions": voicing.preferred_inversions,
    }
