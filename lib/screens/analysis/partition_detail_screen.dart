import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/harmonie_app_bar.dart';

class PartitionDetailScreen extends StatelessWidget {
  final String? partitionUrl;
  final String? svgContent;

  const PartitionDetailScreen({
    super.key,
    this.partitionUrl,
    this.svgContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: HarmonieAppBar(
        title: 'Partition & Export',
        actions: [
          if (partitionUrl != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: HarmonieColors.gold),
              onPressed: () {
                // Logique de partage
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMainPreview(),
            const SizedBox(height: 32),
            _buildExportOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPreview() {
    if (svgContent != null && svgContent!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Aperçu notation', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                Icon(Icons.zoom_in_rounded, color: HarmonieColors.gold.withOpacity(0.5), size: 16),
              ],
            ),
            const Divider(),
            SvgPicture.string(
              svgContent!,
              width: double.infinity,
              placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HarmonieColors.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_fix_high_rounded, color: HarmonieColors.gold, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Partition en cours...',
            style: TextStyle(color: HarmonieColors.cream, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'L\'aperçu visuel sera disponible dès que la conversion au format MusicXML sera terminée.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HarmonieColors.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (partitionUrl != null)
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Télécharger le PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HarmonieColors.gold,
                foregroundColor: HarmonieColors.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options d\'exportation',
          style: TextStyle(color: HarmonieColors.cream, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ExportTile(
          label: 'Format PDF',
          subtitle: 'Idéal pour l\'impression',
          icon: Icons.picture_as_pdf_rounded,
          onTap: () {},
        ),
        _ExportTile(
          label: 'MusicXML',
          subtitle: 'Ouvrir dans MuseScore ou Sibelius',
          icon: Icons.code_rounded,
          onTap: () {},
        ),
        _ExportTile(
          label: 'Fichier MIDI',
          subtitle: 'Importer dans votre DAW',
          icon: Icons.audiotrack_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ExportTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ExportTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HarmonieColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: HarmonieColors.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: HarmonieColors.gold, size: 20),
        ),
        title: Text(label, style: const TextStyle(color: HarmonieColors.cream, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: HarmonieColors.muted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: HarmonieColors.muted),
      ),
    );
  }
}
