// lib/screens/record_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../models/instrument.dart';
import '../widgets/instrument_card.dart';
import '../widgets/harmonie_app_bar.dart';

// ─── Machine d'états de l'enregistrement ─────────────────────────────────────
enum _Phase { idle, recording, paused, reviewing }

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with TickerProviderStateMixin {
  String _selectedInstrumentId = 'guitar_acoustic';
  _Phase _phase = _Phase.idle;
  bool _isAnalysing = false;
  String? _recordingPath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  double _amplitude = 0.0;
  StreamSubscription? _ampSub;
  late AnimationController _pulseController;

  // Player de réécoute
  final _player = AudioPlayer();
  bool _playerReady = false;
  StreamSubscription? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _playerStateSub =
        _player.playerStateStream.listen((_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _pulseController.dispose();
    _player.dispose();
    _playerStateSub?.cancel();
    AudioService.cancelRecording();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _start() async {
    final path = await AudioService.startRecording();
    if (path == null) { _showError('Permission micro refusée'); return; }
    setState(() {
      _phase = _Phase.recording;
      _recordingPath = path;
      _elapsed = Duration.zero;
      _playerReady = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _elapsed += const Duration(seconds: 1)));
    _ampSub = AudioService.amplitudeStream.listen((amp) {
      if (mounted) {
        final val = amp?.current ?? -60.0;
        setState(() => _amplitude = ((val + 60) / 60).clamp(0.0, 1.0));
      }
    });
  }

  Future<void> _pause() async {
    _timer?.cancel();
    _ampSub?.cancel();
    await AudioService.pauseRecording();
    setState(() { _phase = _Phase.paused; _amplitude = 0.0; });
  }

  Future<void> _resume() async {
    await AudioService.resumeRecording();
    setState(() => _phase = _Phase.recording);
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _elapsed += const Duration(seconds: 1)));
    _ampSub = AudioService.amplitudeStream.listen((amp) {
      if (mounted) {
        final val = amp?.current ?? -60.0;
        setState(() => _amplitude = ((val + 60) / 60).clamp(0.0, 1.0));
      }
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _ampSub?.cancel();
    final path = await AudioService.stopRecording();
    if (path == null) return;
    setState(() {
      _phase = _Phase.reviewing;
      _recordingPath = path;
      _amplitude = 0.0;
    });
    // Charger le fichier dans le player
    try {
      await _player.setFilePath(path);
      if (mounted) setState(() => _playerReady = true);
    } catch (_) {}
  }

  Future<void> _restart() async {
    await _player.stop();
    await AudioService.cancelRecording();
    // Supprimer le fichier temporaire
    if (_recordingPath != null) {
      try { await File(_recordingPath!).delete(); } catch (_) {}
    }
    setState(() {
      _phase = _Phase.idle;
      _recordingPath = null;
      _elapsed = Duration.zero;
      _amplitude = 0.0;
      _playerReady = false;
    });
  }

  Future<void> _analyse() async {
    if (_recordingPath == null) return;
    await _player.stop();
    setState(() => _isAnalysing = true);
    try {
      final file = File(_recordingPath!);
      String fileUrl = '';
      try {
        fileUrl = await SupabaseService.uploadFile(
            file: file, bucket: 'audio', folder: 'recordings');
      } catch (_) {}

      // Analyse réelle via ton serveur Python
      final result = await ApiService.analyze(
          file: file,
          targetKey: _selectedInstrumentId);

      try {
        await SupabaseService.saveSession(
          title: 'Enregistrement ${_formatDate()}',
          instrumentId: _selectedInstrumentId,
          fileUrl: fileUrl,
          fileType: 'audio',
          analysisResult: result.toJson(),
        );
      } catch (_) {}

      if (mounted) {
        setState(() => _isAnalysing = false);
        context.push('/analyser/resultat', extra: {
          'result': result,
          'fileName': 'Enregistrement ${_formatDate()}',
          'instrumentId': _selectedInstrumentId,
          'localFilePath': _recordingPath,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalysing = false);
        _showError('Erreur : $e');
      }
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: HarmonieAppBar(title: 'Enregistrement studio'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Micro animé ──────────────────────────────────────────────
            if (_phase != _Phase.reviewing) ...[
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final isActive = _phase == _Phase.recording;
                    final scale = isActive
                        ? 1.0 + (_amplitude * 0.35) + (_pulseController.value * 0.05)
                        : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: GestureDetector(
                    onTap: _isAnalysing
                        ? null
                        : _phase == _Phase.recording
                            ? _stop
                            : _phase == _Phase.paused
                                ? _resume
                                : _start,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _phase == _Phase.recording
                            ? HarmonieColors.error.withValues(alpha: 0.15)
                            : _phase == _Phase.paused
                                ? HarmonieColors.warning.withValues(alpha: 0.15)
                                : HarmonieColors.gold.withValues(alpha: 0.1),
                        border: Border.all(
                          color: _phase == _Phase.recording
                              ? HarmonieColors.error
                              : _phase == _Phase.paused
                                  ? HarmonieColors.warning
                                  : HarmonieColors.gold,
                          width: 2,
                        ),
                        boxShadow: [
                          if (_phase == _Phase.recording)
                            BoxShadow(
                              color: HarmonieColors.error.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          if (_phase == _Phase.paused)
                            BoxShadow(
                              color: HarmonieColors.warning.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                        ],
                      ),
                      child: Icon(
                        _phase == _Phase.recording
                            ? Icons.stop_rounded
                            : _phase == _Phase.paused
                                ? Icons.play_arrow_rounded
                                : Icons.mic_rounded,
                        color: _phase == _Phase.recording
                            ? HarmonieColors.error
                            : _phase == _Phase.paused
                                ? HarmonieColors.warning
                                : HarmonieColors.gold,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Timer
              Center(
                child: Text(
                  AudioService.formatDuration(_elapsed),
                  style: TextStyle(
                    fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                    fontSize: 42,
                    color: _phase == _Phase.recording
                        ? HarmonieColors.error
                        : _phase == _Phase.paused
                            ? HarmonieColors.warning
                            : HarmonieColors.muted,
                  ),
                ),
              ),

              Center(
                child: Text(
                  _phase == _Phase.recording
                      ? 'Appuyez pour arrêter'
                      : _phase == _Phase.paused
                          ? 'En pause — appuyez pour reprendre'
                          : 'Appuyez pour enregistrer',
                  style: const TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w300),
                ),
              ),

              // Contrôles pendant l'enregistrement
              if (_phase == _Phase.recording) ...[
                const SizedBox(height: 20),
                _AmplitudeBar(amplitude: _amplitude),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CtrlButton(
                      icon: Icons.pause_rounded,
                      label: 'Pause',
                      color: HarmonieColors.warning,
                      onTap: _pause,
                    ),
                    const SizedBox(width: 16),
                    _CtrlButton(
                      icon: Icons.close_rounded,
                      label: 'Annuler',
                      color: HarmonieColors.muted,
                      onTap: _restart,
                    ),
                  ],
                ),
              ],

              // Contrôles en pause
              if (_phase == _Phase.paused) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CtrlButton(
                      icon: Icons.fiber_manual_record_rounded,
                      label: 'Continuer',
                      color: HarmonieColors.warning,
                      onTap: _resume,
                    ),
                    const SizedBox(width: 16),
                    _CtrlButton(
                      icon: Icons.stop_rounded,
                      label: 'Terminer',
                      color: HarmonieColors.gold,
                      onTap: _stop,
                    ),
                    const SizedBox(width: 16),
                    _CtrlButton(
                      icon: Icons.close_rounded,
                      label: 'Annuler',
                      color: HarmonieColors.muted,
                      onTap: _restart,
                    ),
                  ],
                ),
              ],
            ],

            // ── Mode réécoute ─────────────────────────────────────────────
            if (_phase == _Phase.reviewing) ...[
              _ReviewPlayer(player: _player, ready: _playerReady),
              const SizedBox(height: 20),
              // Bouton recommencer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh_rounded,
                      color: HarmonieColors.muted, size: 18),
                  label: const Text('Recommencer',
                      style: TextStyle(
                          color: HarmonieColors.muted, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: HarmonieColors.muted, width: 0.8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // ── Instrument ───────────────────────────────────────────────
            Text(
              'Instrument de sortie',
              style: TextStyle(
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                fontSize: 16,
                color: HarmonieColors.cream,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 145,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: InstrumentCatalog.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final instr = InstrumentCatalog.all[i];
                  return InstrumentCard(
                    instrument: instr,
                    isSelected: _selectedInstrumentId == instr.id,
                    onTap: () =>
                        setState(() => _selectedInstrumentId = instr.id),
                  );
                },
              ),
            ),

            // ── Bouton Analyser ───────────────────────────────────────────
            if (_phase == _Phase.reviewing) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAnalysing ? null : _analyse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HarmonieColors.gold,
                    disabledBackgroundColor: HarmonieColors.surface2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isAnalysing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: Colors.black, size: 18),
                            SizedBox(width: 8),
                            Text('Analyser avec l\'IA',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: HarmonieColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Widget réécoute ──────────────────────────────────────────────────────────

class _ReviewPlayer extends StatefulWidget {
  final AudioPlayer player;
  final bool ready;
  const _ReviewPlayer({required this.player, required this.ready});

  @override
  State<_ReviewPlayer> createState() => _ReviewPlayerState();
}

class _ReviewPlayerState extends State<_ReviewPlayer> {
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggle() async {
    if (!widget.ready) return;
    if (widget.player.playing) {
      await widget.player.pause();
    } else {
      if (widget.player.processingState == ProcessingState.completed) {
        await widget.player.seek(Duration.zero);
      }
      await widget.player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: HarmonieColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🎙', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                'Réécoute avant analyse',
                style: TextStyle(
                  fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                  fontSize: 14,
                  color: HarmonieColors.cream,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<Duration>(
            stream: widget.player.positionStream,
            builder: (_, posSnap) {
              return StreamBuilder<Duration?>(
                stream: widget.player.durationStream,
                builder: (_, durSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final dur = durSnap.data ?? Duration.zero;
                  final progress = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    children: [
                      Row(
                        children: [
                          // Play/Pause
                          GestureDetector(
                            onTap: _toggle,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: HarmonieColors.gold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: HarmonieColors.gold
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Icon(
                                widget.player.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTapDown: (d) {
                                    final box = context.findRenderObject()
                                        as RenderBox?;
                                    if (box == null) return;
                                    final ratio = (d.localPosition.dx /
                                            box.size.width)
                                        .clamp(0.0, 1.0);
                                    widget.player.seek(Duration(
                                      milliseconds: (dur.inMilliseconds * ratio)
                                          .round(),
                                    ));
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: HarmonieColors.gold
                                          .withValues(alpha: 0.15),
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                              HarmonieColors.gold),
                                      minHeight: 5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(pos),
                                        style: const TextStyle(
                                            color: HarmonieColors.gold,
                                            fontSize: 11)),
                                    Text(_fmt(dur),
                                        style: const TextStyle(
                                            color: HarmonieColors.muted,
                                            fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Bouton de contrôle ───────────────────────────────────────────────────────

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CtrlButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Barre d'amplitude ────────────────────────────────────────────────────────

class _AmplitudeBar extends StatelessWidget {
  final double amplitude;
  const _AmplitudeBar({required this.amplitude});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(24, (i) {
        final maxH = 4.0 + (i % 6) * 5.0;
        final active = (i / 24) < amplitude;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 5,
          height: active ? maxH * 2 : 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? HarmonieColors.error
                : HarmonieColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
