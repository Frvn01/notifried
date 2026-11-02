import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Lavender/Periwinkle Mode (Default)
  static const Color bgGradientTop = Color(0xFFD7DBF5);
  static const Color bgGradientMid = Color(0xFFCCD2F8);
  static const Color bgGradientBottom = Color(0xFFBAC1F6);
  static const Color bgSolid = Color(0xFFCCD2F8);

  // Dark Mode
  static const Color darkBgTop = Color(0xFF0D0F1B);
  static const Color darkBgMid = Color(0xFF141728);
  static const Color darkBgBottom = Color(0xFF0A0C16);
  static const Color darkCard = Color(0xFF1A1D30);
  static const Color darkText = Color(0xFFF3F4F6);
  static const Color darkTextMuted = Color(0xFF9EA4C6);

  // Surface colors
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardPeach = Color(0xFFFBE4D2);
  static const Color cardSkyBlue = Color(0xFFD6EFF8);
  static const Color cardLavender = Color(0xFFE4E7FC);
  static const Color cardSoftPurple = Color(0xFFECE7FE);

  // Accents & Brand
  static const Color primaryDark = Color(0xFF1E2138);
  static const Color primaryIndigo = Color(0xFF5960A0);
  static const Color accentPurple = Color(0xFF6C5CE7);
  static const Color arrowButtonBg = Color(0xFF5960A0);

  // Text colors
  static const Color textDark = Color(0xFF181B2F);
  static const Color textMuted = Color(0xFF6E7498);
  static const Color textLight = Color(0xFF9EA4C6);

  // Pills & Badges
  static const Color pillDark = Color(0xFF1E2138);
  static const Color pillLight = Color(0xFFEDF1FD);
  static const Color pillTextDark = Color(0xFFFFFFFF);
  static const Color pillTextLight = Color(0xFF494E73);

  // Icon Badge backgrounds
  static const Color iconBadgeBlue = Color(0xFFE4EAFE);
  static const Color iconBadgePurple = Color(0xFFECE6FE);
  static const Color iconBadgePeach = Color(0xFFFDECE2);
  static const Color iconBadgeCyan = Color(0xFFDEF2F9);
}

class AppTheme {
  static ThemeData getTheme({
    Color primaryColor = AppColors.primaryIndigo,
    String themeMode = 'lavender',
  }) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final isDark = themeMode == 'dark';

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0C0E1A)
          : (themeMode == 'light'
              ? const Color(0xFFF5F7FC)
              : const Color(0xFFCCD3FA)),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        surface: isDark ? AppColors.darkCard : AppColors.cardWhite,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkText : AppColors.textDark,
          height: 1.15,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkText : AppColors.textDark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }

  static List<Color> getBackgroundGradient(String themeMode) {
    if (themeMode == 'dark') {
      return const [
        Color(0xFF0C0E1A),
        Color(0xFF131627),
        Color(0xFF090A13),
      ];
    } else if (themeMode == 'light') {
      return const [
        Color(0xFFF5F7FC),
        Color(0xFFEBF0FA),
        Color(0xFFE2E7F4),
      ];
    }
    // Default Lavender
    return const [
      Color(0xFFD6DBF7),
      Color(0xFFCCD3FA),
      Color(0xFFBAC2F5),
    ];
  }
}
