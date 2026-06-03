// lib/utils/chord_database.dart

class ChordFingering {
  final List<int> frets; // e.g. [-1, 3, 2, 0, 1, 0] for C guitar
  final int baseFret;    // 1-indexed starting fret to show on diagram (usually 1)
  final List<int>? fingers; // optional finger positions (1: index, 2: middle, 3: ring, 4: pinky)

  const ChordFingering({
    required this.frets,
    this.baseFret = 1,
    this.fingers,
  });
}

class ChordDatabase {
  // Guitar Chord Definitions (6 strings: Low E, A, D, G, B, High e)
  static const Map<String, ChordFingering> _guitarChords = {
    // C Chords
    'C': ChordFingering(frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]),
    'Cm': ChordFingering(frets: [-1, 3, 5, 5, 4, 3], baseFret: 3),
    'C7': ChordFingering(frets: [-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0]),
    'Cmaj7': ChordFingering(frets: [-1, 3, 2, 0, 0, 0], fingers: [0, 3, 2, 0, 0, 0]),

    // C# / Db Chords
    'C#': ChordFingering(frets: [-1, 4, 6, 6, 6, 4], baseFret: 4),
    'C#m': ChordFingering(frets: [-1, 4, 6, 6, 5, 4], baseFret: 4),
    'C#7': ChordFingering(frets: [-1, 4, 6, 4, 6, 4], baseFret: 4),
    'Db': ChordFingering(frets: [-1, 4, 6, 6, 6, 4], baseFret: 4),
    'Dbm': ChordFingering(frets: [-1, 4, 6, 6, 5, 4], baseFret: 4),

    // D Chords
    'D': ChordFingering(frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]),
    'Dm': ChordFingering(frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1]),
    'D7': ChordFingering(frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3]),
    'Dm7': ChordFingering(frets: [-1, -1, 0, 2, 1, 1], fingers: [0, 0, 0, 2, 1, 1]),
    'Dmaj7': ChordFingering(frets: [-1, -1, 0, 2, 2, 2], fingers: [0, 0, 0, 1, 1, 1]),

    // D# / Eb Chords
    'D#': ChordFingering(frets: [-1, 6, 8, 8, 8, 6], baseFret: 6),
    'D#m': ChordFingering(frets: [-1, 6, 8, 8, 7, 6], baseFret: 6),
    'Eb': ChordFingering(frets: [-1, 6, 8, 8, 8, 6], baseFret: 6),
    'Ebm': ChordFingering(frets: [-1, 6, 8, 8, 7, 6], baseFret: 6),

    // E Chords
    'E': ChordFingering(frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]),
    'Em': ChordFingering(frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0]),
    'E7': ChordFingering(frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0]),
    'Em7': ChordFingering(frets: [0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0]),
    'Emaj7': ChordFingering(frets: [0, 2, 1, 1, 0, 0], baseFret: 1),

    // F Chords
    'F': ChordFingering(frets: [1, 3, 3, 2, 1, 1], baseFret: 1),
    'Fm': ChordFingering(frets: [1, 3, 3, 1, 1, 1], baseFret: 1),
    'F7': ChordFingering(frets: [1, 3, 1, 2, 1, 1], baseFret: 1),
    'Fmaj7': ChordFingering(frets: [-1, 3, 2, 2, 1, 0], baseFret: 1),

    // F# / Gb Chords
    'F#': ChordFingering(frets: [2, 4, 4, 3, 2, 2], baseFret: 2),
    'F#m': ChordFingering(frets: [2, 4, 4, 2, 2, 2], baseFret: 2),
    'F#7': ChordFingering(frets: [2, 4, 2, 3, 2, 2], baseFret: 2),
    'Gb': ChordFingering(frets: [2, 4, 4, 3, 2, 2], baseFret: 2),
    'Gbm': ChordFingering(frets: [2, 4, 4, 2, 2, 2], baseFret: 2),

    // G Chords
    'G': ChordFingering(frets: [3, 2, 0, 0, 0, 3], fingers: [3, 2, 0, 0, 0, 4]),
    'Gm': ChordFingering(frets: [3, 5, 5, 3, 3, 3], baseFret: 3),
    'G7': ChordFingering(frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1]),
    'Gmaj7': ChordFingering(frets: [3, 2, 0, 0, 0, 2], baseFret: 1),

    // G# / Ab Chords
    'G#': ChordFingering(frets: [4, 6, 6, 5, 4, 4], baseFret: 4),
    'G#m': ChordFingering(frets: [4, 6, 6, 4, 4, 4], baseFret: 4),
    'Ab': ChordFingering(frets: [4, 6, 6, 5, 4, 4], baseFret: 4),
    'Abm': ChordFingering(frets: [4, 6, 6, 4, 4, 4], baseFret: 4),

    // A Chords
    'A': ChordFingering(frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0]),
    'Am': ChordFingering(frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]),
    'A7': ChordFingering(frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 1, 0, 2, 0]),
    'Am7': ChordFingering(frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0]),
    'Amaj7': ChordFingering(frets: [-1, 0, 2, 1, 2, 0], fingers: [0, 0, 2, 1, 3, 0]),

    // A# / Bb Chords
    'A#': ChordFingering(frets: [-1, 1, 3, 3, 3, 1], baseFret: 1),
    'A#m': ChordFingering(frets: [-1, 1, 3, 3, 2, 1], baseFret: 1),
    'Bb': ChordFingering(frets: [-1, 1, 3, 3, 3, 1], baseFret: 1),
    'Bbm': ChordFingering(frets: [-1, 1, 3, 3, 2, 1], baseFret: 1),

    // B Chords
    'B': ChordFingering(frets: [-1, 2, 4, 4, 4, 2], baseFret: 2),
    'Bm': ChordFingering(frets: [-1, 2, 4, 4, 3, 2], baseFret: 2),
    'B7': ChordFingering(frets: [-1, 2, 1, 2, 0, 2], fingers: [0, 2, 1, 3, 0, 4]),
    'Bm7': ChordFingering(frets: [-1, 2, 4, 2, 3, 2], baseFret: 2),
  };

  // Ukulele Chord Definitions (4 strings: G, C, E, A)
  static const Map<String, ChordFingering> _ukuleleChords = {
    // C Chords
    'C': ChordFingering(frets: [0, 0, 0, 3], fingers: [0, 0, 0, 3]),
    'Cm': ChordFingering(frets: [0, 3, 3, 3], baseFret: 1),
    'C7': ChordFingering(frets: [0, 0, 0, 1], fingers: [0, 0, 0, 1]),
    'Cmaj7': ChordFingering(frets: [0, 0, 0, 2], fingers: [0, 0, 0, 2]),

    // C# / Db Chords
    'C#': ChordFingering(frets: [1, 1, 1, 4], baseFret: 1),
    'C#m': ChordFingering(frets: [1, 1, 0, 4], baseFret: 1),
    'Db': ChordFingering(frets: [1, 1, 1, 4], baseFret: 1),
    'Dbm': ChordFingering(frets: [1, 1, 0, 4], baseFret: 1),

    // D Chords
    'D': ChordFingering(frets: [2, 2, 2, 0], fingers: [1, 2, 3, 0]),
    'Dm': ChordFingering(frets: [2, 2, 1, 0], fingers: [2, 3, 1, 0]),
    'D7': ChordFingering(frets: [2, 0, 2, 0], fingers: [1, 0, 2, 0]),
    'Dm7': ChordFingering(frets: [2, 2, 1, 3], baseFret: 1),

    // D# / Eb Chords
    'D#': ChordFingering(frets: [0, 3, 3, 1], baseFret: 1),
    'D#m': ChordFingering(frets: [3, 3, 2, 1], baseFret: 1),
    'Eb': ChordFingering(frets: [0, 3, 3, 1], baseFret: 1),
    'Ebm': ChordFingering(frets: [3, 3, 2, 1], baseFret: 1),

    // E Chords
    'E': ChordFingering(frets: [4, 4, 4, 2], baseFret: 1),
    'Em': ChordFingering(frets: [0, 4, 3, 2], fingers: [0, 3, 2, 1]),
    'E7': ChordFingering(frets: [1, 2, 0, 2], fingers: [1, 2, 0, 3]),
    'Em7': ChordFingering(frets: [0, 2, 0, 2], fingers: [0, 1, 0, 2]),

    // F Chords
    'F': ChordFingering(frets: [2, 0, 1, 0], fingers: [2, 0, 1, 0]),
    'Fm': ChordFingering(frets: [1, 0, 1, 3], fingers: [1, 0, 2, 4]),
    'F7': ChordFingering(frets: [2, 3, 1, 0], baseFret: 1),

    // F# / Gb Chords
    'F#': ChordFingering(frets: [3, 1, 2, 1], baseFret: 1),
    'F#m': ChordFingering(frets: [2, 1, 2, 0], baseFret: 1),
    'Gb': ChordFingering(frets: [3, 1, 2, 1], baseFret: 1),
    'Gbm': ChordFingering(frets: [2, 1, 2, 0], baseFret: 1),

    // G Chords
    'G': ChordFingering(frets: [0, 2, 3, 2], fingers: [0, 1, 3, 2]),
    'Gm': ChordFingering(frets: [0, 2, 3, 1], fingers: [0, 2, 3, 1]),
    'G7': ChordFingering(frets: [0, 2, 1, 2], fingers: [0, 2, 1, 3]),
    'Gmaj7': ChordFingering(frets: [0, 2, 2, 2], baseFret: 1),

    // G# / Ab Chords
    'G#': ChordFingering(frets: [5, 3, 4, 3], baseFret: 3),
    'G#m': ChordFingering(frets: [4, 3, 4, 2], baseFret: 2),
    'Ab': ChordFingering(frets: [5, 3, 4, 3], baseFret: 3),
    'Abm': ChordFingering(frets: [4, 3, 4, 2], baseFret: 2),

    // A Chords
    'A': ChordFingering(frets: [2, 1, 0, 0], fingers: [2, 1, 0, 0]),
    'Am': ChordFingering(frets: [2, 0, 0, 0], fingers: [2, 0, 0, 0]),
    'A7': ChordFingering(frets: [1, 0, 0, 0], fingers: [1, 0, 0, 0]),
    'Am7': ChordFingering(frets: [0, 0, 0, 0]),

    // A# / Bb Chords
    'A#': ChordFingering(frets: [3, 2, 1, 1], baseFret: 1),
    'A#m': ChordFingering(frets: [3, 1, 1, 1], baseFret: 1),
    'Bb': ChordFingering(frets: [3, 2, 1, 1], baseFret: 1),
    'Bbm': ChordFingering(frets: [3, 1, 1, 1], baseFret: 1),

    // B Chords
    'B': ChordFingering(frets: [4, 3, 2, 2], baseFret: 2),
    'Bm': ChordFingering(frets: [4, 2, 2, 2], baseFret: 2),
    'B7': ChordFingering(frets: [2, 3, 2, 2], baseFret: 2),
  };

  // Helper to normalize flat/sharp notation or strip additions for fallback matching
  static String _cleanChordName(String name) {
    var cleaned = name.trim();
    // Normalise note naming
    cleaned = cleaned.replaceAll('min', 'm');
    cleaned = cleaned.replaceAll('Maj', 'maj');
    cleaned = cleaned.replaceAll('M7', 'maj7');
    return cleaned;
  }

  /// Get guitar chord diagram fingerings
  static ChordFingering getGuitarChord(String chordName) {
    final clean = _cleanChordName(chordName);
    if (_guitarChords.containsKey(clean)) {
      return _guitarChords[clean]!;
    }
    
    // Fallback logic: try mapping secondary naming or root fallback
    final rootOnly = RegExp(r'^([A-G][#b]?m?)').stringMatch(clean) ?? '';
    if (rootOnly.isNotEmpty && _guitarChords.containsKey(rootOnly)) {
      return _guitarChords[rootOnly]!;
    }

    // Default placeholder pattern (Am style)
    return const ChordFingering(frets: [-1, 0, 2, 2, 1, 0]);
  }

  /// Get ukulele chord diagram fingerings
  static ChordFingering getUkuleleChord(String chordName) {
    final clean = _cleanChordName(chordName);
    if (_ukuleleChords.containsKey(clean)) {
      return _ukuleleChords[clean]!;
    }
    
    // Fallback logic
    final rootOnly = RegExp(r'^([A-G][#b]?m?)').stringMatch(clean) ?? '';
    if (rootOnly.isNotEmpty && _ukuleleChords.containsKey(rootOnly)) {
      return _ukuleleChords[rootOnly]!;
    }

    // Default placeholder pattern (Am style)
    return const ChordFingering(frets: [2, 0, 0, 0]);
  }

  // Piano Key Offsets
  static const Map<String, int> _pianoRootOffsets = {
    'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
    'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
    'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
  };

  /// Get highlighted piano keys. Returns absolute key offsets in an octave range.
  static List<int> getPianoKeys(String chordName) {
    // Parse root note
    String root = '';
    String suffix = '';
    if (chordName.length >= 2 && (chordName[1] == '#' || chordName[1] == 'b')) {
      root = chordName.substring(0, 2);
      suffix = chordName.substring(2);
    } else if (chordName.isNotEmpty) {
      root = chordName.substring(0, 1);
      suffix = chordName.substring(1);
    } else {
      return [];
    }

    final rootOffset = _pianoRootOffsets[root] ?? 0;
    final cleanSuffix = _cleanChordName(suffix);

    List<int> intervals = [0, 4, 7]; // Default Major
    if (cleanSuffix == 'm') {
      intervals = [0, 3, 7];
    } else if (cleanSuffix == '7') {
      intervals = [0, 4, 7, 10];
    } else if (cleanSuffix == 'm7') {
      intervals = [0, 3, 7, 10];
    } else if (cleanSuffix == 'maj7') {
      intervals = [0, 4, 7, 11];
    } else if (cleanSuffix == 'sus4' || cleanSuffix == 'sus') {
      intervals = [0, 5, 7];
    } else if (cleanSuffix == 'sus2') {
      intervals = [0, 2, 7];
    } else if (cleanSuffix == 'dim') {
      intervals = [0, 3, 6];
    } else if (cleanSuffix == 'aug') {
      intervals = [0, 4, 8];
    } else if (cleanSuffix == '6') {
      intervals = [0, 4, 7, 9];
    } else if (cleanSuffix == 'm6') {
      intervals = [0, 3, 7, 9];
    } else if (cleanSuffix == '9') {
      intervals = [0, 4, 7, 10, 14];
    }

    return intervals.map((interval) => rootOffset + interval).toList();
  }
}
