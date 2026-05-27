// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bg = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1A2235);
  static const Color cardBorder = Color(0xFF243050);

  static const Color bgLight = Color(0xFFF0F4FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFDDE3F0);

  static const Color neonGreen = Color(0xFF00C07A);
  static const Color neonBlue = Color(0xFF0099CC);
  static const Color neonPink = Color(0xFFE0008A);
  static const Color neonYellow = Color(0xFFFFD60A);

  static const Color textPrimary = Color(0xFFE8F0FE);
  static const Color textSecondary = Color(0xFF8899B8);
  static const Color textPrimaryLight = Color(0xFF0D1524);
  static const Color textSecondaryLight = Color(0xFF5A6A8A);

  static const Color income = Color(0xFF00C07A);
  static const Color expense = Color(0xFFE0008A);
  static const Color divider = Color(0xFF1E2D45);

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00F5A0), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF3CAC), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color bgOf(bool dark) => dark ? bg : bgLight;
  static Color surfaceOf(bool dark) => dark ? surface : surfaceLight;
  static Color cardOf(bool dark) => dark ? card : cardLight;
  static Color cardBorderOf(bool dark) => dark ? cardBorder : cardBorderLight;
  static Color textPrimaryOf(bool dark) => dark ? textPrimary : textPrimaryLight;
  static Color textSecondaryOf(bool dark) => dark ? textSecondary : textSecondaryLight;
}

class AppTheme {
  static ThemeData dark = ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.neonGreen,
      secondary: AppColors.neonBlue,
      surface: AppColors.surface,
      error: AppColors.neonPink,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    useMaterial3: true,
  );

  static ThemeData light = ThemeData(
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.neonGreen,
      secondary: AppColors.neonBlue,
      surface: AppColors.surfaceLight,
      error: AppColors.neonPink,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme)
        .apply(bodyColor: AppColors.textPrimaryLight, displayColor: AppColors.textPrimaryLight),
    useMaterial3: true,
  );
}
