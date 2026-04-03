// lib/widgets/notation_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/preferences_service.dart';

/// Affiché une seule fois au premier lancement pour choisir la notation musicale.
Future<void> showNotationDialog(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: HarmonieColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (_) => const _NotationSheet(),
  );
}

class _NotationSheet extends StatelessWidget {
  const _NotationSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        36 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
       child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: HarmonieColors.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          const Text('🎵', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),

          Text(
            'Comment lis-tu les notes ?',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 22,
              color: HarmonieColors.cream,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisis la notation musicale à utiliser dans toute l\'application.',
            style: TextStyle(
              color: HarmonieColors.muted,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Option Français
          _NotationOption(
            flag: '🇫🇷',
            language: 'Français',
            example: 'Do · Ré · Mi · Fa · Sol · La · Si',
            description: 'Notation solfège (Europe francophone)',
            onTap: () async {
              await PreferencesService.setNotation(true);
              if (context.mounted) Navigator.pop(context);
            },
          ),

          const SizedBox(height: 12),

          // Option Anglais
          _NotationOption(
            flag: '🇬🇧',
            language: 'Anglais',
            example: 'C · D · E · F · G · A · B',
            description: 'Notation anglosaxonne (internationale)',
            onTap: () async {
              await PreferencesService.setNotation(false);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
       ),
      ),
    );
  }
}

class _NotationOption extends StatelessWidget {
  final String flag;
  final String language;
  final String example;
  final String description;
  final VoidCallback onTap;

  const _NotationOption({
    required this.flag,
    required this.language,
    required this.example,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HarmonieColors.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HarmonieColors.gold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: const TextStyle(
                      color: HarmonieColors.cream,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    example,
                    style: const TextStyle(
                      color: HarmonieColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: HarmonieColors.muted, size: 14),
          ],
        ),
      ),
    );
  }
}
