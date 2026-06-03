// lib/widgets/audio_waveform.dart
// Waveform visuelle interactive avec seekable cursor + surbrillance accord actif
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_theme.dart';
import '../models/music_result.dart';

class AudioWaveform extends StatefulWidget {
  final AudioPlayer player;
  final AudioFeatures? audioFeatures;
  final List<ChordEvent> chordTimeline;

  const AudioWaveform({
    super.key,
    required this.player,
    this.audioFeatures,
    this.chordTimeline = const [],
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform> {
  StreamSubscription<Duration>? _posSub;
  double _progress = 0.0; // 0.0 → 1.0
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _posSub = widget.player.positionStream.listen((pos) {
      if (!mounted || _dragging) return;
      final dur = widget.player.duration;
      if (dur != null && dur.inMilliseconds > 0) {
        setState(() => _progress = pos.inMilliseconds / dur.inMilliseconds);
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  void _seekTo(double localX, double width) {
    final ratio = (localX / width).clamp(0.0, 1.0);
    final dur = widget.player.duration;
    if (dur != null) {
      widget.player.seek(Duration(milliseconds: (dur.inMilliseconds * ratio).toInt()));
      setState(() => _progress = ratio);
    }
  }

  /// Finds the chord active at a given progress ratio (0-1)
  String? _chordAt(double ratio) {
    final dur = widget.player.duration?.inMilliseconds;
    if (dur == null || dur == 0 || widget.chordTimeline.isEmpty) return null;
    final sec = ratio * dur / 1000.0;
    for (final e in widget.chordTimeline) {
      if (sec >= e.start && sec < e.end) return e.chord;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth;
      return GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => _seekTo(d.localPosition.dx, w),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onTapDown: (d) => _seekTo(d.localPosition.dx, w),
        child: SizedBox(
          height: 64,
          width: w,
          child: CustomPaint(
            painter: _WaveformPainter(
              progress: _progress,
              beatTimes: widget.audioFeatures?.beatTimes ?? [],
              totalDuration: widget.audioFeatures?.durationSeconds ?? 0.0,
              chordTimeline: widget.chordTimeline,
              activeChord: _chordAt(_progress),
            ),
          ),
        ),
      );
    });
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final List<double> beatTimes;
  final double totalDuration;
  final List<ChordEvent> chordTimeline;
  final String? activeChord;

  _WaveformPainter({
    required this.progress,
    required this.beatTimes,
    required this.totalDuration,
    required this.chordTimeline,
    this.activeChord,
  });

  static const _chordColors = [
    Color(0xFFE8B84B), // gold
    Color(0xFF8B5CF6), // violet
    Color(0xFF2DD4BF), // teal
    Color(0xFFF472B6), // rose
    Color(0xFF34D399), // green
    Color(0xFF60A5FA), // blue
    Color(0xFFFBBF24), // amber
    Color(0xFFA78BFA), // purple
  ];

  Color _colorForChord(String chord) {
    return _chordColors[chord.hashCode.abs() % _chordColors.length];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    // ── Background ──────────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1830)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(12)),
      bgPaint,
    );

    if (totalDuration <= 0) {
      // Empty state: draw placeholder bars
      _drawPlaceholderBars(canvas, size);
      _drawCursor(canvas, size);
      return;
    }

    // ── Chord segment colored bands ──────────────────────────────────────────
    for (int i = 0; i < chordTimeline.length; i++) {
      final e = chordTimeline[i];
      final x1 = (e.start / totalDuration * w).clamp(0.0, w);
      final x2 = (e.end / totalDuration * w).clamp(0.0, w);
      final color = _colorForChord(e.chord);
      final isActive = (progress * totalDuration) >= e.start &&
          (progress * totalDuration) < e.end;

      final bandPaint = Paint()
        ..color = color.withOpacity(isActive ? 0.18 : 0.07)
        ..style = PaintingStyle.fill;

      canvas.drawRect(Rect.fromLTWH(x1, 0, x2 - x1, h), bandPaint);
    }

    // ── Beat tick marks ──────────────────────────────────────────────────────
    final beatPaint = Paint()
      ..color = HarmonieColors.muted.withOpacity(0.25)
      ..strokeWidth = 1.0;

    for (final bt in beatTimes) {
      final x = (bt / totalDuration * w).clamp(0.0, w);
      canvas.drawLine(Offset(x, h * 0.3), Offset(x, h * 0.7), beatPaint);
    }

    // ── Chord boundary lines ─────────────────────────────────────────────────
    for (final e in chordTimeline) {
      final x = (e.start / totalDuration * w).clamp(0.0, w);
      final color = _colorForChord(e.chord);
      final linePaint = Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
    }

    // ── Played (filled) track ────────────────────────────────────────────────
    final playedX = (progress * w).clamp(0.0, w);
    // Find current chord colour
    String? curChord;
    for (final e in chordTimeline) {
      if ((progress * totalDuration) >= e.start &&
          (progress * totalDuration) < e.end) {
        curChord = e.chord;
        break;
      }
    }
    final playColor = curChord != null
        ? _colorForChord(curChord)
        : HarmonieColors.gold;

    // Gradient bar (played)
    final playedGrad = Paint()
      ..shader = LinearGradient(
        colors: [playColor.withOpacity(0.7), playColor.withOpacity(0.3)],
      ).createShader(Rect.fromLTWH(0, h * 0.45, playedX, h * 0.1));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.45, playedX, h * 0.1),
        const Radius.circular(4),
      ),
      playedGrad,
    );

    // Remaining track (dim)
    final remainPaint = Paint()
      ..color = HarmonieColors.muted.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(playedX, h * 0.45, w - playedX, h * 0.1),
        const Radius.circular(4),
      ),
      remainPaint,
    );

    _drawCursor(canvas, size);
  }

  void _drawPlaceholderBars(Canvas canvas, Size size) {
    const barCount = 40;
    final barW = size.width / (barCount * 2);
    final midY = size.height / 2;
    final barPaint = Paint()
      ..color = HarmonieColors.muted.withOpacity(0.15)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barW;

    for (var i = 0; i < barCount; i++) {
      final x = barW + i * barW * 2;
      final barH = ((i * 7 + 11) % 30 + 8).toDouble();
      canvas.drawLine(
        Offset(x, midY - barH / 2),
        Offset(x, midY + barH / 2),
        barPaint,
      );
    }
  }

  void _drawCursor(Canvas canvas, Size size) {
    final cursorX = (progress * size.width).clamp(2.0, size.width - 2);

    // Glow
    canvas.drawCircle(
      Offset(cursorX, size.height / 2),
      10,
      Paint()
        ..color = HarmonieColors.gold.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Cursor line
    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, size.height),
      Paint()
        ..color = HarmonieColors.gold
        ..strokeWidth = 2.0,
    );
    // Cursor dot
    canvas.drawCircle(
      Offset(cursorX, size.height / 2),
      5,
      Paint()..color = HarmonieColors.gold,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter o) =>
      o.progress != progress || o.activeChord != activeChord;
}
