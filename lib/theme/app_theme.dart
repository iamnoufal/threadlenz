import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  static const Color emeraldPrimary = Color(0xFF0F4C3A); // Deep rich green
  static const Color emeraldDark = Color(0xFF072A20);
  static const Color goldAccent = Color(0xFFD4AF37); // Classic Gold
  static const Color sandBackground = Color(
    0xFFF9F9F4,
  ); // Off-white/cream paper
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFE5E5E5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: sandBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldPrimary,
        primary: emeraldPrimary,
        secondary: goldAccent,
        surface: Colors.white,
        background: sandBackground,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: emeraldPrimary,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.lato(fontSize: 16, color: textDark, height: 1.5),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14,
          color: textDark.withOpacity(0.8),
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldPrimary,
          foregroundColor: textLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: sandBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: emeraldPrimary),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: emeraldPrimary,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
