// lib/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';

/// Provider pour la notation musicale (Anglais vs Français)
/// Adapté pour Riverpod 3.x (Utilise Notifier au lieu de StateProvider)
final settingsProvider = NotifierProvider<SettingsNotifier, bool>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<bool> {
  @override
  bool build() {
    return PreferencesService.useFrenchNotation;
  }

  void toggleNotation() {
    state = !state;
    PreferencesService.setNotation(state);
  }
}
