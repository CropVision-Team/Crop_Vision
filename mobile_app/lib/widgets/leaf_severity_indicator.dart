import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The app's signature visual element. Instead of a generic circular
/// badge or progress ring, severity is shown as an actual leaf shape
/// whose fill color moves through the real botanical decay sequence
/// (green -> yellow -> rust -> char) as severity_percent increases.
/// A farmer who has looked at ten real diseased leaves will recognize
/// this color language immediately - it's not decoration, it's the
/// same visual information they already read off a plant by eye.
class LeafSeverityIndicator extends StatelessWidget {
  final double severityPercent;
  final String stageCode; // G0-G3
  final String stageLabel;
  final double size;

  const LeafSeverityIndicator({
    super.key,
    required this.severityPercent,
    required this.stageCode,
    required this.stageLabel,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final color = severityColorForPercent(severityPercent);
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _LeafPainter(color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$stageCode · $stageLabel',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          '${severityPercent.toStringAsFixed(1)}% leaf area affected',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.ink.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;
  _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Leaf silhouette: a pointed oval built from two cubic bezier
    // curves meeting at a tip (top) and a base notch (bottom) -
    // roughly how a simple broadleaf outline reads at a glance.
    final path = Path()
      ..moveTo(w / 2, h * 0.05) // tip
      ..cubicTo(w * 0.95, h * 0.25, w * 0.85, h * 0.85, w / 2, h * 0.95)
      ..cubicTo(w * 0.15, h * 0.85, w * 0.05, h * 0.25, w / 2, h * 0.05)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.85), color],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);

    // Midrib + a few side veins - ties the shape to real leaf anatomy
    // rather than reading as an abstract blob.
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(w / 2, h * 0.12), Offset(w / 2, h * 0.88), veinPaint);
    for (final t in [0.30, 0.48, 0.66]) {
      final y = h * t;
      canvas.drawLine(Offset(w / 2, y), Offset(w * 0.72, y - h * 0.06), veinPaint);
      canvas.drawLine(Offset(w / 2, y), Offset(w * 0.28, y - h * 0.06), veinPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) =>
      oldDelegate.color != color;
}
