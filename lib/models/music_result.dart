// lib/models/music_result.dart

class MusicResult {
  final String jobId;
  final String inputType;
  final String status;
  final int totalDurationMs;
  final AudioFeatures? audioFeatures;
  final List<Note> notes;
  final HarmonyResult? harmony;
  final LyricsResult? lyrics;
  final SheetMusicResult? sheetMusic;
  final List<StepResult> steps;
  final String targetInstrument;
  final List<String> warnings;

  MusicResult({
    required this.jobId,
    required this.inputType,
    required this.status,
    required this.totalDurationMs,
    this.audioFeatures,
    required this.notes,
    this.harmony,
    this.lyrics,
    this.sheetMusic,
    required this.steps,
    this.targetInstrument = '',
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get isPartial => status == 'partial';

  factory MusicResult.fromJson(Map<String, dynamic> json) {
    return MusicResult(
      jobId: json['job_id'] ?? '',
      inputType: json['input_type'] ?? '',
      status: json['status'] ?? '',
      totalDurationMs: json['total_duration_ms'] ?? 0,
      audioFeatures: json['audio_features'] != null 
          ? AudioFeatures.fromJson(json['audio_features']) 
          : null,
      notes: (json['notes'] as List? ?? [])
          .map((n) => Note.fromJson(n))
          .toList(),
      harmony: json['harmony'] != null 
          ? HarmonyResult.fromJson(json['harmony']) 
          : null,
      lyrics: json['lyrics'] != null 
          ? LyricsResult.fromJson(json['lyrics']) 
          : null,
      sheetMusic: json['sheet_music'] != null 
          ? SheetMusicResult.fromJson(json['sheet_music']) 
          : null,
      steps: (json['steps'] as List? ?? [])
          .map((s) => StepResult.fromJson(s))
          .toList(),
      targetInstrument: json['target_instrument'] ?? '',
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'input_type': inputType,
      'status': status,
      'total_duration_ms': totalDurationMs,
      'audio_features': audioFeatures?.toJson(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'harmony': harmony?.toJson(),
      'lyrics': lyrics?.toJson(),
      'sheet_music': sheetMusic?.toJson(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'target_instrument': targetInstrument,
      'warnings': warnings,
    };
  }
  static MusicResult demo() {
    return MusicResult(
      jobId: 'demo-job-123',
      inputType: 'audio',
      status: 'completed',
      totalDurationMs: 120000,
      audioFeatures: AudioFeatures(
        bpm: 120,
        key: 'C',
        mode: 'Major',
        keySignature: 'C major',
        durationSeconds: 120.0,
      ),
      notes: [
        Note(note: 'C4', midi: 60, onset: 0.0, duration: 1.0),
        Note(note: 'E4', midi: 64, onset: 1.0, duration: 1.0),
        Note(note: 'G4', midi: 67, onset: 2.0, duration: 1.0),
      ],
      harmony: HarmonyResult(
        keySignature: 'C major',
        chordProgression: ['C', 'F', 'G', 'C'],
        musicxmlAvailable: false,
      ),
      steps: [
        StepResult(name: 'upload', status: 'completed', durationMs: 500),
        StepResult(name: 'transcription', status: 'completed', durationMs: 5000),
      ],
    );
  }
}

class AudioFeatures {
  final double bpm;
  final String key;
  final String mode;
  final String keySignature;
  final double durationSeconds;
  final double? energy;
  final double? danceability;

  AudioFeatures({
    required this.bpm,
    required this.key,
    required this.mode,
    required this.keySignature,
    required this.durationSeconds,
    this.energy,
    this.danceability,
  });

  factory AudioFeatures.fromJson(Map<String, dynamic> json) {
    return AudioFeatures(
      bpm: (json['bpm'] ?? 0).toDouble(),
      key: json['key'] ?? '',
      mode: json['mode'] ?? '',
      keySignature: json['key_signature'] ?? '',
      durationSeconds: (json['duration_seconds'] ?? 0).toDouble(),
      energy: json['energy']?.toDouble(),
      danceability: json['danceability']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'key': key,
      'mode': mode,
      'key_signature': keySignature,
      'duration_seconds': durationSeconds,
    };
  }
}

class Note {
  final String note;
  final int midi;
  final double onset;
  final double duration;
  final double? frequencyHz;

  Note({
    required this.note,
    required this.midi,
    required this.onset,
    required this.duration,
    this.frequencyHz,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      note: json['note'] ?? '',
      midi: json['midi'] ?? 0,
      onset: (json['onset'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      frequencyHz: json['frequency_hz']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note': note,
      'midi': midi,
      'onset': onset,
      'duration': duration,
    };
  }
}

class ChordEvent {
  final String chord;
  final double start;
  final double end;

  ChordEvent({required this.chord, required this.start, required this.end});

  factory ChordEvent.fromJson(Map<String, dynamic> json) {
    return ChordEvent(
      chord: json['chord'] ?? '',
      start: (json['start'] ?? 0).toDouble(),
      end: (json['end'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'chord': chord,
    'start': start,
    'end': end,
  };
}

class HarmonyResult {
  final String keySignature;
  final double keyConfidence;
  final List<String> chordProgression;
  final List<ChordEvent> chordsTimeline;
  final int totalChords;
  final bool musicxmlAvailable;

  HarmonyResult({
    required this.keySignature,
    this.keyConfidence = 0.0,
    required this.chordProgression,
    this.chordsTimeline = const [],
    this.totalChords = 0,
    this.musicxmlAvailable = false,
  });

  factory HarmonyResult.fromJson(Map<String, dynamic> json) {
    return HarmonyResult(
      keySignature: json['key_signature'] ?? '',
      keyConfidence: (json['key_confidence'] ?? 0).toDouble(),
      chordProgression: List<String>.from(json['chord_progression'] ?? []),
      chordsTimeline: (json['chords_timeline'] as List? ?? [])
          .map((e) => ChordEvent.fromJson(e))
          .toList(),
      totalChords: json['total_chords'] ?? 0,
      musicxmlAvailable: json['musicxml_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key_signature': keySignature,
      'key_confidence': keyConfidence,
      'chord_progression': chordProgression,
      'chords_timeline': chordsTimeline.map((e) => e.toJson()).toList(),
      'total_chords': totalChords,
      'musicxml_available': musicxmlAvailable,
    };
  }
}

class LyricsResult {
  final String text;
  final String language;

  LyricsResult({required this.text, required this.language});

  factory LyricsResult.fromJson(Map<String, dynamic> json) {
    return LyricsResult(
      text: json['text'] ?? '',
      language: json['language'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
    };
  }
}

class SheetMusicResult {
  final String keySignature;
  final String timeSignature;
  final String? svgContent;
  final String? pdfPath;
  final String? svgPath;
  final String? musicxmlPath;

  SheetMusicResult({
    required this.keySignature, 
    required this.timeSignature,
    this.svgContent,
    this.pdfPath,
    this.svgPath,
    this.musicxmlPath,
  });

  factory SheetMusicResult.fromJson(Map<String, dynamic> json) {
    return SheetMusicResult(
      keySignature: json['key_signature'] ?? '',
      timeSignature: json['time_signature'] ?? '',
      svgContent: json['svg_content'],
      pdfPath: json['pdf_path'],
      svgPath: json['svg_path'],
      musicxmlPath: json['musicxml_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key_signature': keySignature,
      'time_signature': timeSignature,
      'svg_content': svgContent,
      'pdf_path': pdfPath,
      'svg_path': svgPath,
      'musicxml_path': musicxmlPath,
    };
  }
}

class StepResult {
  final String name;
  final String status;
  final int durationMs;
  final String? error;

  StepResult({
    required this.name,
    required this.status,
    required this.durationMs,
    this.error,
  });

  factory StepResult.fromJson(Map<String, dynamic> json) {
    return StepResult(
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      durationMs: json['duration_ms'] ?? 0,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'duration_ms': durationMs,
      'error': error,
    };
  }
}
