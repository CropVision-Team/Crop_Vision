import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens grounded in real plant pathology: healthy leaves decay
/// through green -> chlorotic yellow -> rust necrosis -> charred brown
/// as disease progresses. That real botanical sequence is used as the
/// severity gradient throughout the app instead of a generic traffic-
/// light red/yellow/green.
class AppColors {
  static const canopy = Color(0xFF2F5233); // healthy leaf green (severity data)
  static const chlorotic = Color(0xFFD9A62E); // early disease yellowing
  static const rust = Color(0xFFB5651D); // necrotic rust-brown
  static const char = Color(0xFF3B2A20); // charred/critical necrosis

  // Dark Theme Palette
  static const darkBg = Color(0xFF10181A); // near-black deep teal
  static const darkSurface = Color(0xFF1C2A2C); // card/surface on dark bg
  static const darkSurfaceElevated = Color(0xFF243638); // slightly lighter, for elevated elements
  static const neon = Color(0xFF8CFF3B); // bright lime-green accent
  static const neonDim = Color(0xFF5FCC1F); // slightly deeper, for gradients
  static const ink = Color(0xFFEAF2EC); // near-white text on dark backgrounds
  static const inkMuted = Color(0xFFA9BDB6); // secondary text on dark backgrounds

  // Light Theme Palette
  static const lightBg = Color(0xFFF2F6F3); // fresh, clean soft pale green-gray
  static const lightSurface = Color(0xFFFFFFFF); // crisp white cards
  static const lightSurfaceElevated = Color(0xFFE5EDE7); // subtle elevated surfaces
  static const lightInk = Color(0xFF13221C); // dark slate teal text
  static const lightInkMuted = Color(0xFF5A7067); // muted secondary text
  static const lightAccent = Color(0xFF237A3B); // vibrant leaf green accent

  // Legacy parchment palette
  static const parchment = Color(0xFFF6F3EA);
}

/// Continuous interpolation through the decay sequence, driven by the
/// actual severity percentage (0-100).
Color severityColorForPercent(double percent) {
  final p = percent.clamp(0, 100) / 100;
  if (p <= 0.33) {
    return Color.lerp(AppColors.canopy, AppColors.chlorotic, p / 0.33)!;
  } else if (p <= 0.66) {
    return Color.lerp(AppColors.chlorotic, AppColors.rust, (p - 0.33) / 0.33)!;
  }
  return Color.lerp(AppColors.rust, AppColors.char, (p - 0.66) / 0.34)!;
}

class AppTheme {
  static const displayFont = GoogleFonts.spaceGrotesk;
  static const bodyFont = GoogleFonts.inter;

  /// Dark Theme
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neon,
        secondary: AppColors.canopy,
        surface: AppColors.darkSurface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.inkMuted,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
    );

    return _buildTheme(base, isDark: true);
  }

  /// Light Theme
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightAccent,
        secondary: AppColors.canopy,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightInk,
        onSurfaceVariant: AppColors.lightInkMuted,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightSurface,
    );

    return _buildTheme(base, isDark: false);
  }

  static ThemeData _buildTheme(ThemeData base, {required bool isDark}) {
    final textColor = isDark ? AppColors.ink : AppColors.lightInk;
    final mutedTextColor = isDark ? AppColors.inkMuted : AppColors.lightInkMuted;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final elevatedColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    final primaryAccent = isDark ? AppColors.neon : AppColors.lightAccent;

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            headlineSmall: displayFont(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            titleLarge: displayFont(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            titleMedium: displayFont(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            bodyLarge: bodyFont(fontSize: 16, color: textColor),
            bodyMedium: bodyFont(fontSize: 14, color: textColor),
            bodySmall: bodyFont(fontSize: 12, color: mutedTextColor),
          )
          .apply(bodyColor: textColor, displayColor: textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: displayFont(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: mutedTextColor),
      ),
      iconTheme: IconThemeData(color: mutedTextColor, size: 24),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? AppColors.neon.withValues(alpha: 0.15)
                : AppColors.lightAccent.withValues(alpha: 0.12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: isDark ? AppColors.darkBg : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: bodyFont(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryAccent.withValues(alpha: isDark ? 0.2 : 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryAccent, width: 1.5),
        ),
        labelStyle: TextStyle(color: mutedTextColor),
        hintStyle: TextStyle(color: mutedTextColor),
      ),
    );
  }
}
