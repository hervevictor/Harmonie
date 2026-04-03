// lib/widgets/instrument_card.dart
import 'package:flutter/material.dart';
import '../models/instrument.dart';
import '../theme/app_theme.dart';

class InstrumentCard extends StatelessWidget {
  final Instrument instrument;
  final bool isSelected;
  final VoidCallback onTap;

  const InstrumentCard({
    super.key,
    required this.instrument,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? instrument.accentColor.withOpacity(0.15)
              : HarmonieColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? instrument.accentColor.withOpacity(0.7)
                : const Color(0x12FFFFFF),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: instrument.accentColor.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? instrument.accentColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(color: const Color(0x20FFFFFF)),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 11, color: Colors.black)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Emoji
            Text(instrument.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            // Name
            Text(
              instrument.name,
              style: const TextStyle(
                color: HarmonieColors.cream,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              instrument.familyLabel,
              style: const TextStyle(
                color: HarmonieColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Difficulty dots
            Row(
              children: List.generate(5, (i) => Container(
                width: 10,
                height: 3,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: i < instrument.difficulty
                      ? instrument.accentColor
                      : const Color(0x20FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

