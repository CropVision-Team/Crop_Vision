import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CropVision Farmer-First Theme System
/// Fresh Green (#2E7D32) primary, high sunlight legibility, friendly rounded curves.
class AppColors {
  // ── Primary Brand ─────────────────────────────────────────────────
  static const primary       = Color(0xFF2E7D32);   // Farm Green
  static const primaryDeep   = Color(0xFF1B5E20);   // Dark Green
  static const primaryLight  = Color(0xFFE8F5E9);   // Pale Green Wash
  static const teal          = Color(0xFF2E7D32);   // Alias to primary green
  static const tealDeep      = Color(0xFF1B5E20);
  static const tealSoft      = Color(0xFF4CAF50);
  static const indigo        = Color(0xFF388E3C);
  static const indigoDeep    = Color(0xFF1B5E20);

  // ── Severity Scale (Accessible with clear icon & text) ────────────
  static const severityG0    = Color(0xFF2E7D32);   // G0: Healthy Forest Green
  static const severityG1    = Color(0xFFF59E0B);   // G1: Mild Yellow/Amber
  static const severityG2    = Color(0xFFD97706);   // G2: Moderate Orange
  static const severityG3    = Color(0xFFC62828);   // G3: Critical Earth Red

  // ── Dark Mode Surfaces (Optional night mode) ──────────────────────
  static const darkBg              = Color(0xFF111815);
  static const darkSurface         = Color(0xFF1B2420);
  static const darkSurfaceElevated = Color(0xFF25332C);
  static const darkBorder          = Color(0xFF2D3C33);
  static const inkLight            = Color(0xFFF1F5F2);
  static const inkMuted            = Color(0xFF9EABA2);

  // ── Light Mode Surfaces (Default: Anti-glare outdoors) ────────────
  static const lightBg              = Color(0xFFF8FAF6);   // Soft warm cream
  static const lightSurface         = Color(0xFFFFFFFF);   // Pure white card
  static const lightSurfaceElevated = Color(0xFFF1F5EB);   // Soft tinted surface
  static const lightBorder          = Color(0xFFE2E8F0);   // Crisp light border
  static const lightInk             = Color(0xFF1C2826);   // High-contrast slate
  static const lightInkMuted        = Color(0xFF4A5568);   // Readable slate gray

  // ── Backwards compat aliases ──────────────────────────────────────
  static const forest      = primaryDeep;
  static const canopy      = primary;
  static const terracotta  = Color(0xFFD97706);
  static const rust        = terracotta;
  static const sage        = Color(0xFF43A047);
  static const moss        = primaryDeep;
  static const neon        = primaryLight;
  static const parchment   = lightBg;
  static const ink         = inkLight;
  static const lightAccent = primary;
  static const chlorotic   = severityG1;
  static const char        = Color(0xFF1C2826);
}

Color severityColorForPercent(double percent) {
  final p = percent.clamp(0, 100) / 100;
  if (p <= 0.25) {
    return Color.lerp(AppColors.severityG0, AppColors.severityG1, p / 0.25)!;
  } else if (p <= 0.50) {
    return Color.lerp(AppColors.severityG1, AppColors.severityG2, (p - 0.25) / 0.25)!;
  }
  return Color.lerp(AppColors.severityG2, AppColors.severityG3, (p - 0.50) / 0.50)!;
}

class AppTheme {
  static const displayFont = GoogleFonts.nunito;
  static const bodyFont = GoogleFonts.inter;

  /// Light Theme (Default)
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryDeep,
        tertiary: AppColors.severityG1,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightInk,
        onSurfaceVariant: AppColors.lightInkMuted,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightSurface,
    );
    return _buildTheme(base, isDark: false);
  }

  /// Dark Theme
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        tertiary: AppColors.severityG1,
        surface: AppColors.darkSurface,
        onSurface: AppColors.inkLight,
        onSurfaceVariant: AppColors.inkMuted,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
    );
    return _buildTheme(base, isDark: true);
  }

  static ThemeData _buildTheme(ThemeData base, {required bool isDark}) {
    final textColor      = isDark ? AppColors.inkLight : AppColors.lightInk;
    final mutedTextColor = isDark ? AppColors.inkMuted : AppColors.lightInkMuted;
    const primaryAccent  = AppColors.primary;
    final surfaceColor   = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevatedColor  = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            headlineSmall: displayFont(
              fontSize: 24, fontWeight: FontWeight.w800,
              letterSpacing: -0.3, color: textColor,
            ),
            titleLarge: displayFont(
              fontSize: 20, fontWeight: FontWeight.w700,
              letterSpacing: -0.2, color: textColor,
            ),
            titleMedium: displayFont(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: textColor,
            ),
            bodyLarge:  bodyFont(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
            bodyMedium: bodyFont(fontSize: 14.5, fontWeight: FontWeight.w400, color: textColor),
            bodySmall:  bodyFont(fontSize: 13,   fontWeight: FontWeight.w500, color: mutedTextColor),
          )
          .apply(bodyColor: textColor, displayColor: textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: displayFont(
          fontSize: 20, fontWeight: FontWeight.w800, color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor, size: 24),
      ),
      iconTheme: IconThemeData(color: textColor, size: 24),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: bodyFont(fontSize: 16.5, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: mutedTextColor, fontSize: 15),
        hintStyle: TextStyle(color: mutedTextColor, fontSize: 14.5),
      ),
    );
  }
}
