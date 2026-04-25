// lib/widgets/notation_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class NotationToggle extends ConsumerWidget {
  const NotationToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useFrench = ref.watch(settingsProvider);

    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).toggleNotation(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: HarmonieColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              useFrench ? 'FR' : 'EN',
              style: GoogleFonts.inter(
                color: HarmonieColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              useFrench ? Icons.language_rounded : Icons.translate_rounded,
              size: 14,
              color: HarmonieColors.gold.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
