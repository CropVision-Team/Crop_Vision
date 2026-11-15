import 'package:flutter/material.dart';
import '../models/diagnosis.dart';

/// Single source of truth for severity -> color mapping, used by both
/// result_screen.dart and history_screen.dart (previously duplicated
/// in each file).
Color severityColor(SeverityStage? stage) {
  if (stage == null) return Colors.grey;
  switch (stage) {
    case SeverityStage.g0:
      return Colors.green;
    case SeverityStage.g1:
      return Colors.yellow.shade700;
    case SeverityStage.g2:
      return Colors.orange;
    case SeverityStage.g3:
      return Colors.red;
  }
}

class SeverityBadge extends StatelessWidget {
  final SeverityStage stage;
  final double? severityPercent;

  const SeverityBadge({super.key, required this.stage, this.severityPercent});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(stage);
    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Text(stage.code,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (severityPercent != null)
                    Text('${severityPercent!.toStringAsFixed(1)}% of leaf area affected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
