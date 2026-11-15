import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../models/diagnosis.dart';
import '../widgets/severity_badge.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_design_system.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDiseaseName(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unverified Leaf';
    final parts = raw.split('___');
    final crop = parts[0].replaceAll('_', ' ');
    final disease = parts.length > 1 ? parts[1].replaceAll('_', ' ') : '';
    return disease.isEmpty ? crop : '$crop — $disease';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final borderColor = isDark ? FarmerColors.borderDark : FarmerColors.borderLight;
    final textColor = isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GradientAppBar(title: 'Farm Diagnosis History'),
      body: FutureBuilder<List<Diagnosis>>(
        future: service.fetchDiagnosisHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FarmerColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: FarmerColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, size: 48, color: FarmerColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Leaf Diagnoses Saved Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Whenever you scan a crop leaf, the diagnosis, damage analysis, and medicine guidance will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: mutedTextColor, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/capture'),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Scan Leaf Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: FarmerColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FarmerRadius.pill)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = items[index];
              final color = severityColor(d.severityStage);
              final diseaseName = _formatDiseaseName(d.predictedDisease);

              return Container(
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(FarmerRadius.lg),
                    onTap: () => Navigator.pushNamed(context, '/result', arguments: d),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: d.imageUrl.isNotEmpty
                                ? Image.network(
                                    d.imageUrl,
                                    width: 62,
                                    height: 62,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 62,
                                      height: 62,
                                      color: color.withValues(alpha: 0.12),
                                      child: Icon(Icons.eco_rounded, color: color, size: 28),
                                    ),
                                  )
                                : Container(
                                    width: 62,
                                    height: 62,
                                    color: color.withValues(alpha: 0.12),
                                    child: Icon(Icons.eco_rounded, color: color, size: 28),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          // Disease details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  diseaseName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(FarmerRadius.pill),
                                      ),
                                      child: Text(
                                        d.severityStage?.code ?? 'G0',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        d.createdAt != null
                                            ? '${d.createdAt!.day}/${d.createdAt!.month}/${d.createdAt!.year}'
                                            : 'Recent scan',
                                        style: TextStyle(fontSize: 13, color: mutedTextColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (d.confidence != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: FarmerColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(d.confidence! * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: FarmerColors.primaryDeep,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
