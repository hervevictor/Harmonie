// lib/models/instrument.dart
import 'package:flutter/material.dart';

enum InstrumentFamily {
  cordes,
  vents,
  percussions,
  touches,
  electronique,
}

class Instrument {
  final String id;
  final String name;
  final String emoji;
  final InstrumentFamily family;
  final int difficulty; // 1–5
  final String soundFontId; // identifiant FluidSynth
  final List<String> tuning; // ex: ['E2','A2','D3','G3','B3','E4'] pour guitare
  final Color accentColor;

  const Instrument({
    required this.id,
    required this.name,
    required this.emoji,
    required this.family,
    required this.difficulty,
    required this.soundFontId,
    required this.tuning,
    required this.accentColor,
  });

  String get familyLabel {
    switch (family) {
      case InstrumentFamily.cordes: return 'Cordes pincées';
      case InstrumentFamily.vents: return 'Vents';
      case InstrumentFamily.percussions: return 'Percussions';
      case InstrumentFamily.touches: return 'Touches';
      case InstrumentFamily.electronique: return 'Électronique';
    }
  }
}

// ─── Catalogue complet ────────────────────────────────────────────────────────
class InstrumentCatalog {
  static const List<Instrument> all = [
    Instrument(
      id: 'guitar_acoustic',
      name: 'Guitare acoustique',
      emoji: '🎸',
      family: InstrumentFamily.cordes,
      difficulty: 2,
      soundFontId: 'acoustic_guitar_nylon',
      tuning: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      accentColor: Color(0xFFC9A84C),
    ),
    Instrument(
      id: 'guitar_electric',
      name: 'Guitare électrique',
      emoji: '🎸',
      family: InstrumentFamily.cordes,
      difficulty: 3,
      soundFontId: 'electric_guitar_clean',
      tuning: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      accentColor: Color(0xFFE05555),
    ),
    Instrument(
      id: 'piano',
      name: 'Piano',
      emoji: '🎹',
      family: InstrumentFamily.touches,
      difficulty: 3,
      soundFontId: 'acoustic_grand_piano',
      tuning: [],
      accentColor: Color(0xFFF5EFE0),
    ),
    Instrument(
      id: 'violin',
      name: 'Violon',
      emoji: '🎻',
      family: InstrumentFamily.cordes,
      difficulty: 4,
      soundFontId: 'violin',
      tuning: ['G3', 'D4', 'A4', 'E5'],
      accentColor: Color(0xFFA87DE0),
    ),
    Instrument(
      id: 'flute',
      name: 'Flûte traversière',
      emoji: '🪈',
      family: InstrumentFamily.vents,
      difficulty: 3,
      soundFontId: 'flute',
      tuning: [],
      accentColor: Color(0xFF4CAF82),
    ),
    Instrument(
      id: 'saxophone',
      name: 'Saxophone',
      emoji: '🎷',
      family: InstrumentFamily.vents,
      difficulty: 3,
      soundFontId: 'tenor_sax',
      tuning: [],
      accentColor: Color(0xFFE8A84C),
    ),
    Instrument(
      id: 'trumpet',
      name: 'Trompette',
      emoji: '🎺',
      family: InstrumentFamily.vents,
      difficulty: 4,
      soundFontId: 'trumpet',
      tuning: [],
      accentColor: Color(0xFFE8C97A),
    ),
    Instrument(
      id: 'bass',
      name: 'Guitare basse',
      emoji: '🎸',
      family: InstrumentFamily.cordes,
      difficulty: 2,
      soundFontId: 'electric_bass_finger',
      tuning: ['E1', 'A1', 'D2', 'G2'],
      accentColor: Color(0xFF7C5CBF),
    ),
    Instrument(
      id: 'drums',
      name: 'Batterie',
      emoji: '🥁',
      family: InstrumentFamily.percussions,
      difficulty: 3,
      soundFontId: 'standard_drum_kit',
      tuning: [],
      accentColor: Color(0xFFE05555),
    ),
    Instrument(
      id: 'cello',
      name: 'Violoncelle',
      emoji: '🎻',
      family: InstrumentFamily.cordes,
      difficulty: 5,
      soundFontId: 'cello',
      tuning: ['C2', 'G2', 'D3', 'A3'],
      accentColor: Color(0xFFC9A84C),
    ),
    Instrument(
      id: 'ukulele',
      name: 'Ukulélé',
      emoji: '🪗',
      family: InstrumentFamily.cordes,
      difficulty: 1,
      soundFontId: 'acoustic_guitar_nylon',
      tuning: ['G4', 'C4', 'E4', 'A4'],
      accentColor: Color(0xFF4CAF82),
    ),
    Instrument(
      id: 'harmonica',
      name: 'Harmonica',
      emoji: '🪗',
      family: InstrumentFamily.vents,
      difficulty: 2,
      soundFontId: 'harmonica',
      tuning: [],
      accentColor: Color(0xFF7C5CBF),
    ),
  ];

  static List<Instrument> byFamily(InstrumentFamily family) =>
      all.where((i) => i.family == family).toList();

  static Instrument? findById(String id) =>
      all.cast<Instrument?>().firstWhere((i) => i?.id == id, orElse: () => null);
}
