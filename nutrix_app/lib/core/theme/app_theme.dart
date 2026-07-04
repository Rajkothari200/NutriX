import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary & Brands
  static const Color primary = Color(0xFF22C55E); // Green
  static const Color primaryLight = Color(0xFF4ADE80);
  
  // Specific UI Colors from screenshots
  static const Color purpleAction = Color(0xFF8B5CF6); // Calculate Macros button
  static const Color blueAction = Color(0xFF3B82F6); // Extract & Log Meal button / Tab Active
  static const Color orangeOutline = Color(0xFFFDBA74); // Orange outline buttons
  static const Color textLink = Color(0xFF22C55E); // Green links

  // Backgrounds
  static const Color bgLight = Color(0xFFF8F9FE); // Very light grey/blue app background
  static const Color bgLightCard = Color(0xFFFFFFFF); // Pure white cards
  static const Color bgDarkSurface = Color(0xFFF1F5F9); // Light grey inputs

  // Text Colors
  static const Color textMain = Color(0xFF1E293B); // Slate 800
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textDim = Color(0xFF94A3B8); // Slate 400

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Health score aliases
  static const Color healthy = success;
  static const Color moderate = warning;
  static const Color unhealthy = error;

  // Macros / Analytics
  static const Color calories = Color(0xFFF97316); // Orange
  static const Color protein = Color(0xFF22C55E); // Green
  static const Color carbs = Color(0xFF3B82F6); // Blue
  static const Color fat = Color(0xFFEF4444); // Red
  static const Color fiber = Color(0xFF8B5CF6); // Purple

  // Borders
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Gradient (kept for compatibility)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [bgLightCard, bgLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Aliases for compatibility with old dark mode references
  static const Color bgDark = bgLight;
  static const Color bgDarkCard = bgLightCard;
  static const Color textDark = textMain;
  static const Color textDarkMuted = textMuted;
  static const Color accent = blueAction;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.blueAction,
        surface: AppColors.bgLightCard,
        error: AppColors.error,
        onSurface: AppColors.textMain,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          letterSpacing: 0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textMain,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLightCard,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgLightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLight, // slight off-white for inputs
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textDim,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgLightCard,
        selectedItemColor: AppColors.blueAction,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      dividerColor: AppColors.border,
    );
  }
}
