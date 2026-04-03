// lib/services/progress_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/course_model.dart';

class ProgressService {
  static Map<String, String> _data = {};
  static bool _loaded = false;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/learn_progress.json');
  }

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = await f.readAsString();
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _data = map.map((k, v) => MapEntry(k, v as String));
      }
    } catch (_) {}
    _loaded = true;
  }

  static Future<void> _save() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(_data));
    } catch (_) {}
  }

  // ── Section progress ───────────────────────────────────────────────────────

  static Future<void> markSection(
      String courseId, String sectionId, SectionStatus status) async {
    await load();
    _data['$courseId:$sectionId'] = status.name;
    await _save();
  }

  static Future<SectionStatus> getSectionStatus(
      String courseId, String sectionId) async {
    await load();
    final v = _data['$courseId:$sectionId'];
    return switch (v) {
      'completed' => SectionStatus.completed,
      'skipped' => SectionStatus.skipped,
      _ => SectionStatus.notStarted,
    };
  }

  /// Returns count of completed sections for a course.
  static Future<int> completedSections(String courseId, int total) async {
    await load();
    int count = 0;
    for (var i = 0; i < total; i++) {
      final v = _data['$courseId:section_$i'];
      if (v == 'completed') count++;
    }
    // Also check by sectionId keys
    count = 0;
    _data.forEach((key, value) {
      if (key.startsWith('$courseId:') && value == 'completed') count++;
    });
    return count;
  }

  // ── Instrument & level choice ─────────────────────────────────────────────

  static Future<void> saveLastInstrument(String instrumentId) async {
    await load();
    _data['lastInstrument'] = instrumentId;
    await _save();
  }

  static String get lastInstrument => _data['lastInstrument'] ?? 'guitar_acoustic';

  static Future<void> saveLevelForInstrument(
      String instrumentId, CourseLevel level) async {
    await load();
    _data['level:$instrumentId'] = level.name;
    await _save();
  }

  static CourseLevel levelForInstrument(String instrumentId) {
    final v = _data['level:$instrumentId'];
    return CourseLevel.values.firstWhere((l) => l.name == v,
        orElse: () => CourseLevel.beginner);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    _data.clear();
    await _save();
  }
}
