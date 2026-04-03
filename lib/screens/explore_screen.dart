import 'package:google_fonts/google_fonts.dart';
// lib/screens/explore_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: HarmonieColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: HarmonieColors.gold.withOpacity(0.3)),
                ),
                child: const Center(child: Text('🎵', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 24),
               Text('Explorer',
                  style: TextStyle(fontFamily: GoogleFonts.playfairDisplay().fontFamily, fontSize: 24, color: HarmonieColors.cream)),
              const SizedBox(height: 12),
              const Text('Découvrez des chansons, des accords et des mélodies du monde entier.',
                  style: TextStyle(color: HarmonieColors.muted, fontSize: 14, height: 1.6, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: HarmonieColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HarmonieColors.gold.withOpacity(0.2)),
                ),
                child: const Text('🚧  En développement',
                    style: TextStyle(color: HarmonieColors.gold, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
