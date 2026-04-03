// lib/widgets/upload_zone.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UploadZone extends StatelessWidget {
  final VoidCallback onTapUpload;
  final VoidCallback onTapRecord;

  const UploadZone({
    super.key,
    required this.onTapUpload,
    required this.onTapRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HarmonieColors.gold.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapUpload,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HarmonieColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    color: HarmonieColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Importer ou enregistrer',
                        style: TextStyle(
                          color: HarmonieColors.cream,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Fichier audio, vidéo, partition ou image',
                        style: TextStyle(
                          color: HarmonieColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          ...<String>['MP3', 'WAV', 'MP4', 'PDF', 'JPG']
                              .map((f) => _FormatPill(label: f)),
                          GestureDetector(
                            onTap: onTapRecord,
                            child: const _FormatPill(
                              label: '🎙 Enreg.',
                              isHighlighted: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: HarmonieColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatPill extends StatelessWidget {
  final String label;
  final bool isHighlighted;
  const _FormatPill({required this.label, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlighted
            ? HarmonieColors.gold.withOpacity(0.15)
            : const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlighted
              ? HarmonieColors.gold.withOpacity(0.4)
              : const Color(0x18FFFFFF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isHighlighted ? HarmonieColors.gold : HarmonieColors.muted,
        ),
      ),
    );
  }
}
