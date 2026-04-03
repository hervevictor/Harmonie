// lib/services/preferences_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PreferencesService {
  static bool _useFrenchNotation = true;
  static bool _hasSelectedNotation = false;

  static bool get useFrenchNotation => _useFrenchNotation;
  static bool get hasSelectedNotation => _hasSelectedNotation;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/harmonie_prefs.json');
  }

  /// À appeler au démarrage de l'app (dans main()).
  static Future<void> load() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _useFrenchNotation = data['useFrenchNotation'] as bool? ?? true;
        _hasSelectedNotation = data['hasSelectedNotation'] as bool? ?? false;
      }
    } catch (_) {}
  }

  /// Sauvegarde la préférence de notation.
  static Future<void> setNotation(bool useFrench) async {
    _useFrenchNotation = useFrench;
    _hasSelectedNotation = true;
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode({
        'useFrenchNotation': useFrench,
        'hasSelectedNotation': true,
      }));
    } catch (_) {}
  }
}
