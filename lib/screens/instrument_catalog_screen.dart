import 'package:google_fonts/google_fonts.dart';
// lib/screens/instrument_catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/instrument.dart';
import '../widgets/instrument_card.dart';
import '../widgets/harmonie_app_bar.dart';

class InstrumentCatalogScreen extends StatefulWidget {
  const InstrumentCatalogScreen({super.key});

  @override
  State<InstrumentCatalogScreen> createState() =>
      _InstrumentCatalogScreenState();
}

class _InstrumentCatalogScreenState extends State<InstrumentCatalogScreen> {
  final Set<String> _selected = {'guitar_acoustic'};

  @override
  Widget build(BuildContext context) {
    final families = InstrumentFamily.values;

    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: HarmonieAppBar(
        title: 'Instruments',
        actions: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HarmonieColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HarmonieColors.gold.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_selected.length} sélectionné${_selected.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: HarmonieColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HarmonieColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x12FFFFFF)),
            ),
            child: const Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sélectionnez un ou plusieurs instruments pour recevoir notes, accords et mélodies adaptés.',
                    style: TextStyle(
                      color: HarmonieColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Par famille
          ...families.map((family) {
            final instruments =
                InstrumentCatalog.byFamily(family);
            if (instruments.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: HarmonieColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _familyLabel(family),
                        style:  TextStyle(
                          fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                          fontSize: 16,
                          color: HarmonieColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 155,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: instruments.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, i) => InstrumentCard(
                      instrument: instruments[i],
                      isSelected:
                          _selected.contains(instruments[i].id),
                      onTap: () => setState(() {
                        if (_selected.contains(instruments[i].id)) {
                          if (_selected.length > 1) {
                            _selected.remove(instruments[i].id);
                          }
                        } else {
                          _selected.add(instruments[i].id);
                        }
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
      bottomNavigationBar: _selected.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HarmonieColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Confirmer ${_selected.length} instrument${_selected.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _familyLabel(InstrumentFamily family) {
    switch (family) {
      case InstrumentFamily.cordes:
        return '🎸 Cordes';
      case InstrumentFamily.vents:
        return '🎺 Vents';
      case InstrumentFamily.percussions:
        return '🥁 Percussions';
      case InstrumentFamily.touches:
        return '🎹 Touches';
      case InstrumentFamily.electronique:
        return '🎛 Électronique';
    }
  }
}
