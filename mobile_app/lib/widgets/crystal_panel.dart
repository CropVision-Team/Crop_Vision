import 'dart:ui';

import 'package:flutter/material.dart';

/// A native Flutter glass/crystal surface. It deliberately uses no generated
/// raster asset, so it remains sharp on every device and works offline.
class CrystalPanel extends StatelessWidget {
  const CrystalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.accent = const Color(0xFF8CFF3B),
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [Colors.white.withValues(alpha: 0.10), const Color(0xFF1C2A2C).withValues(alpha: 0.78)]
                  : [Colors.white.withValues(alpha: 0.92), const Color(0xFFE5EDE7).withValues(alpha: 0.75)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.20 : 0.78)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: dark ? 0.15 : 0.08), blurRadius: 28, offset: const Offset(0, 14)),
              BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.24 : 0.06), blurRadius: 24, offset: const Offset(0, 12)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
