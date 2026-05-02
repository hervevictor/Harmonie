// lib/screens/history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/analysis_entry.dart';
import '../models/instrument.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/harmonie_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AnalysisEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _entries = HistoryService.getAll());

  Future<void> _delete(AnalysisEntry entry) async {
    await HistoryService.remove(entry.id);
    _reload();
  }

  Future<bool?> _confirmDelete(AnalysisEntry entry) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HarmonieColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?', style: TextStyle(color: HarmonieColors.cream)),
        content: Text(
          'Supprimer « ${entry.title} » de l\'historique ?',
          style: const TextStyle(color: HarmonieColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: HarmonieColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _open(AnalysisEntry entry) {
    context.push('/analyser/resultat', extra: {
      'result': entry.result,
      'localFilePath': entry.audioPath,
      'instrumentId': entry.instrumentId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: const HarmonieAppBar(title: 'Historique'),
      body: _entries.isEmpty ? _buildEmpty() : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: HarmonieColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: HarmonieColors.gold, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune analyse sauvegardée',
            style: GoogleFonts.playfairDisplay(
              color: HarmonieColors.cream,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analysez un fichier puis appuyez sur\nl\'icône favori pour le sauvegarder.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HarmonieColors.muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final grouped = _groupByDate(_entries);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final item = grouped[i];
        if (item is String) {
          return _DateHeader(label: item);
        }
        final entry = item as AnalysisEntry;
        return _HistoryCard(
          entry: entry,
          onTap: () => _open(entry),
          onDismiss: () async {
            final confirmed = await _confirmDelete(entry);
            if (confirmed == true) {
              await _delete(entry);
            } else {
              setState(() {});
            }
          },
        );
      },
    );
  }

  List<dynamic> _groupByDate(List<AnalysisEntry> entries) {
    final result = <dynamic>[];
    String? lastLabel;
    for (final entry in entries) {
      final label = _dateLabel(entry.savedAt);
      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(entry);
    }
    return result;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    if (diff < 7) return DateFormat('EEEE', 'fr_FR').format(dt);
    return DateFormat('d MMMM yyyy', 'fr_FR').format(dt);
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: HarmonieColors.gold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AnalysisEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _HistoryCard({
    required this.entry,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final instr = InstrumentCatalog.findById(entry.instrumentId);
    final af = entry.result.audioFeatures;
    final chordCount = entry.result.harmony?.chordProgression.length ?? 0;
    final noteCount = entry.result.notes.length;
    final time = DateFormat('HH:mm').format(entry.savedAt);
    final audioExists = entry.audioPath != null && File(entry.audioPath!).existsSync();

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDismiss();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HarmonieColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              // Instrument emoji
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: HarmonieColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(instr?.emoji ?? '🎵', style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              color: HarmonieColors.cream,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(color: HarmonieColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (af != null) ...[
                          _Chip(label: '${af.bpm.toInt()} BPM'),
                          const SizedBox(width: 6),
                          _Chip(label: af.keySignature),
                          const SizedBox(width: 6),
                        ],
                        _Chip(label: '$chordCount accords'),
                        const SizedBox(width: 6),
                        _Chip(label: '$noteCount notes'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          audioExists
                              ? Icons.audio_file_rounded
                              : Icons.audio_file_outlined,
                          size: 12,
                          color: audioExists
                              ? HarmonieColors.gold.withValues(alpha: 0.7)
                              : HarmonieColors.muted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          audioExists ? 'Audio disponible' : 'Audio introuvable',
                          style: TextStyle(
                            color: audioExists
                                ? HarmonieColors.muted
                                : HarmonieColors.muted.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: HarmonieColors.muted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: HarmonieColors.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: HarmonieColors.muted, fontSize: 10),
      ),
    );
  }
}
