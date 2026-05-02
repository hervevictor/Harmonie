// lib/models/analysis_entry.dart
import 'music_result.dart';

class AnalysisEntry {
  final String id;
  final DateTime savedAt;
  final String title;
  final String instrumentId;
  final String? audioPath;
  final MusicResult result;

  AnalysisEntry({
    required this.id,
    required this.savedAt,
    required this.title,
    required this.instrumentId,
    this.audioPath,
    required this.result,
  });

  factory AnalysisEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisEntry(
      id: json['id'] as String,
      savedAt: DateTime.parse(json['saved_at'] as String),
      title: json['title'] as String? ?? 'Sans titre',
      instrumentId: json['instrument_id'] as String? ?? 'guitar_acoustic',
      audioPath: json['audio_path'] as String?,
      result: MusicResult.fromJson(json['result'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'saved_at': savedAt.toIso8601String(),
        'title': title,
        'instrument_id': instrumentId,
        'audio_path': audioPath,
        'result': result.toJson(),
      };
}
