import 'package:flutter/material.dart';
import '../models/diagnosis.dart';
import '../theme/app_design_system.dart';
import '../widgets/leaf_severity_indicator.dart';
import '../widgets/gradient_app_bar.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  String _formatDiseaseName(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown';
    final parts = raw.split('___');
    final crop = parts[0].replaceAll('_', ' ');
    final disease = parts.length > 1 ? parts[1].replaceAll('_', ' ') : '';
    return disease.isEmpty ? crop : '$crop — $disease';
  }

  String _buildDiagnosisContext(Diagnosis d) {
    final parts = <String>[];
    if (d.predictedDisease != null) {
      parts.add('Diagnosed Disease: ${_formatDiseaseName(d.predictedDisease)}');
    }
    if (d.confidence != null) {
      parts.add('AI Confidence: ${(d.confidence! * 100).toStringAsFixed(1)}%');
    }
    if (d.severityStage != null) {
      parts.add('Severity Stage: ${d.severityStage!.code} (${d.severityStage!.label})');
    }
    if (d.severityPercent != null) {
      parts.add('Affected Leaf Area: ${d.severityPercent!.toStringAsFixed(1)}%');
    }
    if (d.treatmentRecommendation != null) {
      parts.add('Prescribed Treatment: ${d.treatmentRecommendation}');
    }
    if (d.preventionTips != null) {
      parts.add('Prevention Advice: ${d.preventionTips}');
    }
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final diagnosis = ModalRoute.of(context)?.settings.arguments as Diagnosis?;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;
    final cardBg = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final borderColor = isDark ? FarmerColors.borderDark : FarmerColors.borderLight;

    if (diagnosis == null) {
      return const Scaffold(
        appBar: GradientAppBar(title: 'Diagnosis Result'),
        body: Center(
          child: Text('No diagnosis data found.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    // ── Rejected / Not a leaf ──────────────────────────────────────────
    if (!diagnosis.isValidLeaf) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Photo Verification Failed'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: FarmerColors.alertBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 64, color: FarmerColors.alertRed),
              ),
              const SizedBox(height: 20),
              Text(
                'Please Take a Clear Photo of a Leaf',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                diagnosis.rejectionReason ?? 'Image could not be clearly verified as a crop leaf.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: mutedTextColor, height: 1.4),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Retake Photo'),
                style: FilledButton.styleFrom(
                  backgroundColor: FarmerColors.primary,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FarmerRadius.pill)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    // ── Unknown / unsupported crop ──────────────────────────────────────
    if (diagnosis.isUnknownCrop) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Crop Not Recognized'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: FarmerColors.warningBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, size: 64, color: FarmerColors.warningAmber),
              ),
              const SizedBox(height: 20),
              Text(
                'Crop Pattern Not Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'This leaf does not match supported crops (Tomato, Potato, Corn, Apple, Grape). Please try taking a brighter photo under natural sunlight.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: mutedTextColor, height: 1.4),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Try Another Leaf'),
                style: FilledButton.styleFrom(
                  backgroundColor: FarmerColors.primary,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FarmerRadius.pill)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    // ── Normal diagnosis result ─────────────────────────────────────────
    final stage = diagnosis.severityStage!;
    final displayName = _formatDiseaseName(diagnosis.predictedDisease);
    final diagnosisContext = _buildDiagnosisContext(diagnosis);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Diagnosis & Remedy'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Leaf Image
            ClipRRect(
              borderRadius: BorderRadius.circular(FarmerRadius.lg),
              child: diagnosis.imageUrl.isNotEmpty
                  ? Image.network(
                      diagnosis.imageUrl,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(FarmerRadius.lg),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined, size: 48, color: mutedTextColor),
                              const SizedBox(height: 8),
                              Text('Leaf photo preview saved', style: TextStyle(color: mutedTextColor)),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: FarmerColors.primaryLight,
                        borderRadius: BorderRadius.circular(FarmerRadius.lg),
                      ),
                      child: const Icon(Icons.eco_rounded, size: 64, color: FarmerColors.primary),
                    ),
            ),

            const SizedBox(height: 18),

            // 2. Disease Name & Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(FarmerRadius.lg),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FarmerColors.primaryLight,
                          borderRadius: BorderRadius.circular(FarmerRadius.pill),
                        ),
                        child: Text(
                          'STAGE ${stage.code}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: FarmerColors.primaryDeep,
                          ),
                        ),
                      ),
                      if (diagnosis.confidence != null)
                        Text(
                          '${(diagnosis.confidence! * 100).toInt()}% Confidence',
                          style: const TextStyle(
                            color: FarmerColors.primaryDeep,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: stage.code == 'G0' ? FarmerColors.healthyGreen : FarmerColors.warningAmber,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Severity indicator
            Center(
              child: LeafSeverityIndicator(
                severityPercent: diagnosis.severityPercent ?? 0,
                stageCode: stage.code,
                stageLabel: stage.label,
                size: 110,
              ),
            ),

            const SizedBox(height: 18),

            // 4. Prescribed Treatment card (High contrast)
            _FarmerInfoCard(
              icon: Icons.medical_services_rounded,
              iconColor: FarmerColors.warningAmber,
              iconBg: FarmerColors.warningBg,
              title: 'Recommended Medicine & Spray',
              body: diagnosis.treatmentRecommendation ??
                  'Leaf canopy is healthy. Continue standard organic bio-fertilizer schedule.',
              textColor: textColor,
              mutedColor: mutedTextColor,
              cardBg: cardBg,
              borderColor: borderColor,
            ),

            const SizedBox(height: 12),

            // 5. Prevention guidance
            _FarmerInfoCard(
              icon: Icons.shield_rounded,
              iconColor: FarmerColors.primary,
              iconBg: FarmerColors.primaryLight,
              title: 'Farm Prevention Tips',
              body: diagnosis.preventionTips ??
                  'Maintain furrow spacing, avoid overhead wetting, and scout crops every 3 days.',
              textColor: textColor,
              mutedColor: mutedTextColor,
              cardBg: cardBg,
              borderColor: borderColor,
            ),

            const SizedBox(height: 22),

            // 6. Action Buttons
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: FarmerColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FarmerRadius.pill)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text(
                'Ask AI Doctor About This Diagnosis',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/assistant',
                  arguments: {'diagnosisContext': diagnosisContext},
                );
              },
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FarmerRadius.pill)),
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text(
                'Scan Another Leaf',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FarmerInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final Color textColor;
  final Color mutedColor;
  final Color cardBg;
  final Color borderColor;

  const _FarmerInfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.textColor,
    required this.mutedColor,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FarmerRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
