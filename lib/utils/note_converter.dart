// lib/utils/note_converter.dart

/// Convertit les notes et accords entre notation anglaise (C, D, E...)
/// et notation française (Do, Ré, Mi...).
class NoteConverter {
  static const _enToFr = {
    'C': 'Do',
    'D': 'Ré',
    'E': 'Mi',
    'F': 'Fa',
    'G': 'Sol',
    'A': 'La',
    'B': 'Si',
  };


  /// Convertit une note (ex: "C4", "A#3", "Bb5") selon la notation cible.
  /// Si [useFrench] = true → "C4" devient "Do4", "A#3" → "La#3"
  static String convertNote(String note, bool useFrench) {
    if (!useFrench) return note;
    final match = RegExp(r'^([A-G])([#b]?)(\d*)$').firstMatch(note);
    if (match == null) return note;
    final letter = match.group(1)!;
    final accidental = match.group(2)!;
    final octave = match.group(3)!;
    final fr = _enToFr[letter] ?? letter;
    return '$fr$accidental$octave';
  }

  /// Convertit un accord (ex: "Am", "C", "G7", "Cmaj7") selon la notation.
  /// "Am" → "Lam", "C" → "Do", "G7" → "Sol7"
  static String convertChord(String chord, bool useFrench) {
    if (!useFrench) return chord;
    // Lettre de base (A-G) + accidentel optionnel + suffixe (m, maj7, 7, sus, etc.)
    final match = RegExp(r'^([A-G])([#b]?)(.*)$').firstMatch(chord);
    if (match == null) return chord;
    final letter = match.group(1)!;
    final accidental = match.group(2)!;
    final suffix = match.group(3)!;
    final fr = _enToFr[letter] ?? letter;
    return '$fr$accidental$suffix';
  }

  /// Convertit une liste de notes.
  static List<String> convertNotes(List<String> notes, bool useFrench) =>
      notes.map((n) => convertNote(n, useFrench)).toList();

  /// Convertit une liste d'accords.
  static List<String> convertChords(List<String> chords, bool useFrench) =>
      chords.map((c) => convertChord(c, useFrench)).toList();

  /// Retourne le degré harmonique d'un accord dans une tonalité (ex: C dans G -> IV)
  static String getChordDegree(String chord, String key) {
    if (key.isEmpty) return '';
    
    // Simplification : on ne garde que la note de base
    final chordMatch = RegExp(r'^([A-G][#b]?)').firstMatch(chord);
    final keyMatch = RegExp(r'^([A-G][#b]?)').firstMatch(key);
    
    if (chordMatch == null || keyMatch == null) return '';
    
    final chordBase = chordMatch.group(1)!;
    final keyBase = keyMatch.group(1)!;
    
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    
    // Gérer les bémols
    int getIndex(String n) {
      if (n == 'Db') return 1;
      if (n == 'Eb') return 3;
      if (n == 'Gb') return 6;
      if (n == 'Ab') return 8;
      if (n == 'Bb') return 10;
      return notes.indexOf(n);
    }
    
    final chordIdx = getIndex(chordBase);
    final keyIdx = getIndex(keyBase);
    
    if (chordIdx == -1 || keyIdx == -1) return '';
    
    final interval = (chordIdx - keyIdx + 12) % 12;
    
    const degrees = {
      0: 'I',   1: 'bII', 2: 'II',  3: 'bIII',
      4: 'III', 5: 'IV',  6: '#IV', 7: 'V',
      8: 'bVI', 9: 'VI',  10: 'bVII', 11: 'VII'
    };
    
    return degrees[interval] ?? '';
  }

  /// Retourne les exemples de notes selon la notation choisie.
  static String get exampleFr => 'Do · Ré · Mi · Fa · Sol · La · Si';
  static String get exampleEn => 'C · D · E · F · G · A · B';
}
