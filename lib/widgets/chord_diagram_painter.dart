// lib/widgets/chord_diagram_painter.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/chord_database.dart';

class ChordDiagramPainter extends CustomPainter {
  final String chord;
  final String instrumentId; // guitar, piano, ukulele

  ChordDiagramPainter({required this.chord, required this.instrumentId});

  @override
  void paint(Canvas canvas, Size size) {
    if (instrumentId.contains('piano')) {
      _paintPiano(canvas, size);
    } else {
      final isUkulele = instrumentId.contains('ukulele');
      _paintFretboard(canvas, size, isUkulele);
    }
  }

  void _paintFretboard(Canvas canvas, Size size, bool isUkulele) {
    final stringCount = isUkulele ? 4 : 6;
    final fingering = isUkulele 
        ? ChordDatabase.getUkuleleChord(chord) 
        : ChordDatabase.getGuitarChord(chord);

    final isSmall = size.width < 55;
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = isSmall ? 0.8 : 1.5;

    const fretCount = 4;
    final paddingH = isSmall ? 4.0 : 25.0;
    final paddingV = isSmall ? 8.0 : 25.0;
    final boardWidth = size.width - (paddingH * 2);
    final boardHeight = size.height - (paddingV * 2);

    final stringSpacing = boardWidth / (stringCount - 1);
    final fretSpacing = boardHeight / fretCount;

    final baseFret = fingering.baseFret;

    // 1. Dessiner le sillet si baseFret == 1
    if (baseFret == 1) {
      final nutPaint = Paint()
        ..color = HarmonieColors.cream.withOpacity(0.8)
        ..strokeWidth = isSmall ? 2.0 : 4.5;
      canvas.drawLine(
        Offset(paddingH, paddingV),
        Offset(size.width - paddingH, paddingV),
        nutPaint,
      );
    } else if (!isSmall) {
      // Afficher le numéro de frette sur le côté gauche
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${baseFret}fr',
          style: const TextStyle(
            color: HarmonieColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, paddingV + (fretSpacing * 0.35)));
    }

    // 2. Dessiner les frettes
    for (var i = 0; i <= fretCount; i++) {
      // Si c'est le sillet à i=0 et baseFret == 1, on a déjà dessiné le sillet
      if (i == 0 && baseFret == 1) continue;
      final y = paddingV + (i * fretSpacing);
      canvas.drawLine(Offset(paddingH, y), Offset(size.width - paddingH, y), linePaint);
    }

    // 3. Dessiner les cordes
    for (var i = 0; i < stringCount; i++) {
      final x = paddingH + (i * stringSpacing);
      canvas.drawLine(Offset(x, paddingV), Offset(x, size.height - paddingV), linePaint);
    }

    // 4. Dessiner les fingerings
    final dotPaint = Paint()
      ..color = HarmonieColors.gold
      ..style = PaintingStyle.fill;
    
    final glowPaint = Paint()
      ..color = HarmonieColors.gold.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < stringCount; i++) {
      if (i >= fingering.frets.length) continue;
      final fret = fingering.frets[i];
      final x = paddingH + (i * stringSpacing);

      if (fret == -1) {
        // String non jouée: Dessiner un X au dessus
        textPainter.text = TextSpan(
          text: '×',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: isSmall ? 8 : 14,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - (isSmall ? 2.5 : 5), paddingV - (isSmall ? 8 : 18)));
      } else if (fret == 0) {
        // String vide/ouverte: Dessiner un O au dessus
        textPainter.text = TextSpan(
          text: '○',
          style: TextStyle(
            color: HarmonieColors.gold.withOpacity(0.8),
            fontSize: isSmall ? 7 : 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - (isSmall ? 2.5 : 5), paddingV - (isSmall ? 8 : 17)));
      } else {
        // Fret pressée: dessiner le point
        final relativeFret = fret - baseFret;
        if (relativeFret >= 0 && relativeFret < fretCount) {
          final y = paddingV + ((relativeFret + 0.5) * fretSpacing);
          final pos = Offset(x, y);
          
          canvas.drawCircle(pos, isSmall ? 3 : 8, glowPaint);
          canvas.drawCircle(pos, isSmall ? 2 : 5, dotPaint);

          // Afficher le numéro de doigt si présent
          if (!isSmall && fingering.fingers != null && i < fingering.fingers!.length) {
            final finger = fingering.fingers![i];
            if (finger > 0) {
              textPainter.text = TextSpan(
                text: '$finger',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              );
              textPainter.layout();
              textPainter.paint(canvas, Offset(x - 2.5, y - 4));
            }
          }
        }
      }
    }
  }

  void _paintPiano(Canvas canvas, Size size) {
    // 2 octaves = 14 touches blanches
    const totalWhiteKeys = 14;
    final w = size.width;
    final h = size.height;
    final keyWidth = w / totalWhiteKeys;

    final activeKeys = ChordDatabase.getPianoKeys(chord);

    // Semitones à index de touche blanche
    const List<int> semitoneToWhite = [
      0, // C
     -1, // C#
      1, // D
     -1, // D#
      2, // E
      3, // F
     -1, // F#
      4, // G
     -1, // G#
      5, // A
     -1, // A#
      6, // B
    ];

    // Helper to check if a specific key index (0-23) is active
    bool isKeyActive(int keyIndex) {
      return activeKeys.contains(keyIndex) || activeKeys.contains(keyIndex - 12) || activeKeys.contains(keyIndex + 12);
    }

    // 1. Dessiner les touches blanches
    final whitePaint = Paint()
      ..color = const Color(0xFFE5E5EB)
      ..style = PaintingStyle.fill;
    
    final activeWhitePaint = Paint()
      ..color = HarmonieColors.gold
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < totalWhiteKeys; i++) {
      // Déterminer le semitone de cette touche blanche pour voir si elle est active
      int semitone = -1;
      int octave = i ~/ 7;
      int localWhite = i % 7;
      
      // Retrouver la note correspondant à l'index de touche blanche
      for (int s = 0; s < 12; s++) {
        if (semitoneToWhite[s] == localWhite) {
          semitone = s + octave * 12;
          break;
        }
      }

      final isActive = semitone != -1 && isKeyActive(semitone);
      final x = i * keyWidth;
      final rect = Rect.fromLTWH(x, 0, keyWidth, h);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        isActive ? activeWhitePaint : whitePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        borderPaint,
      );
    }

    // 2. Dessiner les touches noires (plus courtes, plus étroites, par dessus)
    final blackPaint = Paint()
      ..color = const Color(0xFF1E1E28)
      ..style = PaintingStyle.fill;

    final activeBlackPaint = Paint()
      ..color = HarmonieColors.gold.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final blackWidth = keyWidth * 0.65;
    final blackHeight = h * 0.6;

    // Gaps entre les touches blanches où il y a des noires
    // Pour une octave: entre 0-1, 1-2, 3-4, 4-5, 5-6
    final List<int> blackLeftWhiteIndices = [0, 1, 3, 4, 5];

    for (int octave = 0; octave < 2; octave++) {
      for (int i = 0; i < blackLeftWhiteIndices.length; i++) {
        final leftWhite = blackLeftWhiteIndices[i] + octave * 7;
        
        // Trouver le semitone correspondant
        int semitone = -1;
        if (i == 0) semitone = 1; // C#
        if (i == 1) semitone = 3; // D#
        if (i == 2) semitone = 6; // F#
        if (i == 3) semitone = 8; // G#
        if (i == 4) semitone = 10; // A#
        semitone += octave * 12;

        final isActive = isKeyActive(semitone);
        final x = (leftWhite + 1) * keyWidth - (blackWidth / 2);
        final rect = Rect.fromLTWH(x, 0, blackWidth, blackHeight);

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          isActive ? activeBlackPaint : blackPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

