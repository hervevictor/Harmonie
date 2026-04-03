// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HarmonieColors {
  // Backgrounds — plus clairs et chauds
  static const bg       = Color(0xFF0F0E17);  // violet profond (pas noir pur)
  static const surface  = Color(0xFF1A1830);  // bleu-violet doux
  static const surface2 = Color(0xFF252340);  // un cran plus clair
  static const surface3 = Color(0xFF302E50);

  // Accents — plus vifs
  static const gold     = Color(0xFFE8B84B);  // or plus saturé
  static const gold2    = Color(0xFFF5D06A);
  static const cream    = Color(0xFFF7F0E6);  // blanc chaud
  static const muted    = Color(0xFF9896B8);  // violet clair lisible

  // Accents principaux — plus vibrants
  static const accent   = Color(0xFF8B5CF6);  // violet vif
  static const accent2  = Color(0xFFBB8BF8);  // lilas clair
  static const teal     = Color(0xFF2DD4BF);  // turquoise vif
  static const rose     = Color(0xFFF472B6);  // rose vif

  // Sémantiques
  static const success  = Color(0xFF34D399);
  static const error    = Color(0xFFF87171);
  static const warning  = Color(0xFFFBBF24);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HarmonieColors.bg,

      colorScheme: const ColorScheme.dark(
        primary: HarmonieColors.gold,
        secondary: HarmonieColors.accent,
        surface: HarmonieColors.surface,
        error: HarmonieColors.error,
        onPrimary: Colors.black,
        onSecondary: HarmonieColors.cream,
        onSurface: HarmonieColors.cream,
      ),

      textTheme: _buildTextTheme(),

      appBarTheme: const AppBarTheme(
        backgroundColor: HarmonieColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: HarmonieColors.cream),
        titleTextStyle: TextStyle(
          color: HarmonieColors.cream,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HarmonieColors.surface,
        selectedItemColor: HarmonieColors.gold,
        unselectedItemColor: HarmonieColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: HarmonieColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x20FFFFFF)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HarmonieColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x20FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x20FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: HarmonieColors.gold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: HarmonieColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HarmonieColors.gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x20FFFFFF),
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: HarmonieColors.surface2,
        selectedColor: HarmonieColors.gold.withOpacity(0.2),
        labelStyle: const TextStyle(color: HarmonieColors.cream, fontSize: 12),
        side: const BorderSide(color: Color(0x20FFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 36, fontWeight: FontWeight.w700, color: HarmonieColors.cream,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 28, fontWeight: FontWeight.w700, color: HarmonieColors.cream,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 22, fontWeight: FontWeight.w400, color: HarmonieColors.cream,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 20, fontWeight: FontWeight.w700, color: HarmonieColors.cream,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.w400, color: HarmonieColors.cream,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 16, fontWeight: FontWeight.w400, color: HarmonieColors.cream,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w500, color: HarmonieColors.cream,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w500, color: HarmonieColors.cream,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w500, color: HarmonieColors.cream,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.w300, color: HarmonieColors.cream,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w300, color: HarmonieColors.cream,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w300, color: HarmonieColors.muted,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w500,
        letterSpacing: 0.8, color: HarmonieColors.gold,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w500,
        letterSpacing: 0.5, color: HarmonieColors.muted,
      ),
    );
  }
}