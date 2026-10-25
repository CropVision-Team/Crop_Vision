import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../models/diagnosis.dart';
import '../widgets/severity_badge.dart';
import '../widgets/gradient_app_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final cardBg = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GradientAppBar(title: 'Diagnosis History'),
      body: FutureBuilder<List<Diagnosis>>(
        future: service.fetchDiagnosisHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 56, color: mutedTextColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No diagnoses yet', style: TextStyle(color: mutedTextColor)),
                ],
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
              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pushNamed(context, '/result', arguments: d),
                    child: Row(
                      children: [
                        // Severity color accent bar
                        Container(
                          width: 6,
                          height: 76,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        // Thumbnail
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: d.imageUrl.isNotEmpty
                                ? Image.network(
                                    d.imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: color.withValues(alpha: 0.1),
                                      child: Icon(Icons.eco, color: color),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: color.withValues(alpha: 0.1),
                                    child: Icon(Icons.eco, color: color),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  d.predictedDisease ?? 'Unverified image',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        d.severityStage?.code ?? '-',
                                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      d.createdAt != null
                                          ? '${d.createdAt!.day}/${d.createdAt!.month}/${d.createdAt!.year}'
                                          : '',
                                      style: TextStyle(fontSize: 12, color: mutedTextColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (d.confidence != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              '${(d.confidence! * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontWeight: FontWeight.w600, color: mutedTextColor),
                            ),
                          ),
                      ],
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
