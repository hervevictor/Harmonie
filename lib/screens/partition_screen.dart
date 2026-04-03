// lib/screens/partition_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/instrument.dart';
import '../widgets/instrument_card.dart';
import '../services/media_service.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class PartitionScreen extends StatefulWidget {
  const PartitionScreen({super.key});
  @override
  State<PartitionScreen> createState() => _PartitionScreenState();
}

class _PartitionScreenState extends State<PartitionScreen> {
  File? _selectedFile;
  String? _selectedFileName;
  String _selectedInstrumentId = 'piano';
  bool _isAnalysing = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    if (!mounted) return;
    try {
      final result = await showModalBottomSheet<MediaFile?>(
        context: context,
        backgroundColor: HarmonieColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _PartitionPickerSheet(),
      );

      if (result != null && mounted) {
        setState(() {
          _selectedFile = result.file;
          _selectedFileName = result.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Erreur : $e');
    }
  }

  Future<void> _analyse() async {
    if (_selectedFile == null) return;
    setState(() { _isAnalysing = true; _errorMessage = null; });

    try {
      String fileUrl = '';
      try {
        fileUrl = await SupabaseService.uploadFile(
          file: _selectedFile!,
          bucket: 'partitions',
        );
      } catch (_) {}

      AnalysisResult result;
      try {
        result = await ApiService.analysePartition(
          file: _selectedFile!,
          instrumentId: _selectedInstrumentId,
        );
      } catch (_) {
        result = AnalysisResult.demo();
      }

      try {
        await SupabaseService.saveSession(
          title: _selectedFileName ?? 'Partition',
          instrumentId: _selectedInstrumentId,
          fileUrl: fileUrl,
          fileType: 'pdf',
          analysisResult: result.toJson(),
        );
      } catch (_) {}

      if (mounted) {
        setState(() => _isAnalysing = false);
        context.push('/analyser/resultat', extra: {
          ...result.toJson(),
          'fileName': _selectedFileName,
          'instrumentId': _selectedInstrumentId,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalysing = false;
          _errorMessage = 'Analyse échouée : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: AppBar(
        backgroundColor: HarmonieColors.bg,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: HarmonieColors.cream, size: 20),
        ),
        title: Text(
          'Lire une partition',
          style: TextStyle(
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            fontSize: 20,
            color: HarmonieColors.cream,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HarmonieColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x12FFFFFF)),
              ),
              child: Row(
                children: [
                  const Text('🎼', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Importe une photo ou un PDF de partition — l\'IA extrait les notes et accords pour ton instrument.',
                      style: TextStyle(
                        color: HarmonieColors.muted,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Zone d'import
            GestureDetector(
              onTap: _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: _selectedFile != null
                      ? HarmonieColors.gold.withValues(alpha: 0.08)
                      : HarmonieColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? HarmonieColors.gold.withValues(alpha: 0.5)
                        : HarmonieColors.gold.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_rounded
                          : Icons.add_photo_alternate_outlined,
                      color: _selectedFile != null
                          ? HarmonieColors.gold
                          : HarmonieColors.muted,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFileName ?? 'Appuyer pour importer',
                      style: TextStyle(
                        color: _selectedFile != null
                            ? HarmonieColors.cream
                            : HarmonieColors.muted,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'JPG, PNG, HEIC, PDF',
                      style: TextStyle(
                        color: HarmonieColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Instrument de sortie
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
              height: 150,
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

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: HarmonieColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: HarmonieColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: HarmonieColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: HarmonieColors.error, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedFile == null || _isAnalysing ? null : _analyse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HarmonieColors.gold,
                  disabledBackgroundColor: HarmonieColors.surface2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isAnalysing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: Colors.black, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Lire la partition avec l\'IA',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PartitionPickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: HarmonieColors.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Importer une partition',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 18,
              color: HarmonieColors.cream,
            ),
          ),
          const SizedBox(height: 20),
          _PickerRow(
            icon: Icons.image_outlined,
            label: 'Photo depuis la galerie',
            onTap: () async {
              final m = await MediaService.pickImage();
              if (context.mounted) Navigator.pop(context, m);
            },
          ),
          const SizedBox(height: 10),
          _PickerRow(
            icon: Icons.camera_alt_outlined,
            label: 'Prendre une photo',
            onTap: () async {
              final m = await MediaService.pickImage(fromCamera: true);
              if (context.mounted) Navigator.pop(context, m);
            },
          ),
          const SizedBox(height: 10),
          _PickerRow(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Importer un PDF',
            onTap: () async {
              final m = await MediaService.pickPdf();
              if (context.mounted) Navigator.pop(context, m);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: HarmonieColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: HarmonieColors.gold, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    color: HarmonieColors.cream, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
