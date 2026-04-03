import 'package:google_fonts/google_fonts.dart';
// lib/widgets/mode_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String? badge;
  final bool featured;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
    this.featured = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: featured
              ? LinearGradient(
                  colors: [
                    HarmonieColors.accent.withOpacity(0.25),
                    HarmonieColors.gold.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: featured ? null : HarmonieColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: featured
                ? HarmonieColors.accent.withOpacity(0.4)
                : const Color(0x12FFFFFF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: HarmonieColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                fontSize: featured ? 16 : 14,
                color: HarmonieColors.cream,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: HarmonieColors.muted,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
