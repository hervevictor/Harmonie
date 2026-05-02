// lib/services/history_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/analysis_entry.dart';
import '../models/music_result.dart';

class HistoryService {
  static final List<AnalysisEntry> _entries = [];
  static bool _loaded = false;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/harmonie_history.json');
  }

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = await f.readAsString();
        final list = jsonDecode(raw) as List;
        _entries.clear();
        for (final e in list) {
          try {
            _entries.add(AnalysisEntry.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
        }
      }
    } catch (_) {}
    _loaded = true;
  }

  static Future<void> _persist() async {
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  static List<AnalysisEntry> getAll() =>
      (List<AnalysisEntry>.from(_entries)
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt)));

  static bool isSaved(String jobId) =>
      _entries.any((e) => e.result.jobId == jobId);

  static Future<void> add({
    required String title,
    required String instrumentId,
    String? audioPath,
    required MusicResult result,
  }) async {
    if (isSaved(result.jobId)) return;
    _entries.add(AnalysisEntry(
      id: const Uuid().v4(),
      savedAt: DateTime.now(),
      title: title,
      instrumentId: instrumentId,
      audioPath: audioPath,
      result: result,
    ));
    await _persist();
  }

  static Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
  }

  static Future<void> removeByJobId(String jobId) async {
    _entries.removeWhere((e) => e.result.jobId == jobId);
    await _persist();
  }
}
