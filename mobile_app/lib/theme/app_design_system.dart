import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CropVision Farmer-First Shared Design System
/// Specially tailored for outdoor visibility, high contrast,
/// zero tech jargon, and comfortable 48px+ touch targets.
class FarmerColors {
  // Agricultural Greens (Primary)
  static const primary       = Color(0xFF2E7D32); // Fresh Farm Green
  static const primaryDeep   = Color(0xFF1B5E20); // Dark Foliage Green
  static const primaryLight  = Color(0xFFE8F5E9); // Soft Herb Tint
  static const primaryHover  = Color(0xFF256628);

  // Status & Warning Accents (WCAG AA Compliant)
  static const healthyGreen  = Color(0xFF2E7D32);
  static const healthyBg     = Color(0xFFE8F5E9);
  static const warningAmber  = Color(0xFFD97706); // Deep Amber
  static const warningBg     = Color(0xFFFEF3C7);
  static const alertRed      = Color(0xFFC62828); // Vibrant Earth Red
  static const alertBg       = Color(0xFFFFEBEE);
  static const infoBlue      = Color(0xFF0284C7);
  static const infoBg        = Color(0xFFE0F2FE);

  // Light Mode Canvas (Anti-glare in bright sunlight)
  static const bgLight       = Color(0xFFF8FAF6); // Soft warm cream
  static const surfaceLight  = Color(0xFFFFFFFF); // Pure white card
  static const surfaceSubtle = Color(0xFFF1F5EB); // Gentle elevated surface
  static const borderLight   = Color(0xFFE2E8F0); // Subtle neutral border
  static const textDark      = Color(0xFF1C2826); // High-contrast deep slate
  static const textMuted     = Color(0xFF4A5568); // High-contrast readable gray

  // Dark Mode Canvas (Optional night mode)
  static const bgDark        = Color(0xFF111815); // Deep Organic Dark
  static const surfaceDark   = Color(0xFF1B2420); // Dark Card Surface
  static const borderDark    = Color(0xFF2D3A32);
  static const textLight     = Color(0xFFF1F5F2);
  static const textMutedDark = Color(0xFF9EABA2);
}

class FarmerSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class FarmerRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;
}

class FarmerTypography {
  static final TextStyle headline = GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  static final TextStyle title = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
  );
}

/// Farmer Card Container with soft natural elevation
class FarmerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;

  const FarmerCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight);
    final borderColor = border ?? Border.all(
      color: isDark ? FarmerColors.borderDark : FarmerColors.borderLight,
      width: 1,
    );

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FarmerRadius.lg),
        border: borderColor,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FarmerRadius.lg),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(FarmerSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Farmer Status Badge with Icon + Text
class FarmerStatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const FarmerStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  factory FarmerStatusBadge.healthy({String label = 'Healthy (G0)'}) {
    return FarmerStatusBadge(
      label: label,
      icon: Icons.check_circle_rounded,
      color: FarmerColors.healthyGreen,
      backgroundColor: FarmerColors.healthyBg,
    );
  }

  factory FarmerStatusBadge.attention({String label = 'Attention (G2)'}) {
    return FarmerStatusBadge(
      label: label,
      icon: Icons.warning_rounded,
      color: FarmerColors.warningAmber,
      backgroundColor: FarmerColors.warningBg,
    );
  }

  factory FarmerStatusBadge.critical({String label = 'Severe Blight (G3)'}) {
    return FarmerStatusBadge(
      label: label,
      icon: Icons.error_rounded,
      color: FarmerColors.alertRed,
      backgroundColor: FarmerColors.alertBg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(FarmerRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
