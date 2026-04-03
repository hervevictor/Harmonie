// lib/widgets/session_tile.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final double progress; // 0.0 – 1.0
  final int gradientIndex;

  const SessionTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.gradientIndex,
  });

  static const _gradients = [
    [Color(0xFF7C5CBF), Color(0xFFA87DE0)],
    [Color(0xFFC9A84C), Color(0xFFE8C97A)],
    [Color(0xFFE05555), Color(0xFFC9A84C)],
  ];

  @override
  Widget build(BuildContext context) {
    final grad = _gradients[gradientIndex % _gradients.length];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  grad[0].withOpacity(0.4),
                  grad[1].withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: HarmonieColors.cream,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: HarmonieColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 48,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0x18FFFFFF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      HarmonieColors.gold,
                    ),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: HarmonieColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
