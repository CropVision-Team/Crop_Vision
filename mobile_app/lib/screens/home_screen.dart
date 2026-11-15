import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_design_system.dart';
import '../theme/theme_provider.dart';
import '../theme/locale_provider.dart';
import '../models/diagnosis.dart';
import '../data/crop_growth_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  int _cropRefreshKey = 0; // increment to force _CropsGrid to re-fetch

  String _getTimeBasedGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return context.tr('greeting_morning');
    } else if (hour < 17) {
      return context.tr('greeting_afternoon');
    } else {
      return context.tr('greeting_evening');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surfaceColor = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final textColor = isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: FarmerColors.primary,
          backgroundColor: surfaceColor,
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Clean Farmer Header (No cluttered icons)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: FarmerColors.primaryLight,
                                borderRadius: BorderRadius.circular(FarmerRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: FarmerColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('season_badge'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: FarmerColors.primaryDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getTimeBasedGreeting(context),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('home_subtitle'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Single Clean Profile/Settings Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, '/settings'),
                          borderRadius: BorderRadius.circular(FarmerRadius.pill),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? FarmerColors.borderDark : FarmerColors.borderLight,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              size: 22,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 2. HERO ACTION: Big "Scan Crop Leaf" Button (Primary focal point)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _HeroScanCard(
                    onTap: () => Navigator.pushNamed(context, '/capture'),
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Today's Farm Tasks (Actionable schedule, replaces empty 0-stat cards)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _TodayTasksCard(
                    isDark: isDark,
                    onViewCalendar: () async {
                      await Navigator.pushNamed(context, '/calendar');
                      if (mounted) setState(() { _cropRefreshKey++; });
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 4. My Monitored Crops (Dynamic Grid displaying farmer's real planted crops)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('my_crops'),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/calendar');
                          if (mounted) setState(() { _cropRefreshKey++; });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: FarmerColors.primary),
                        label: Text(
                          context.tr('track_crop'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: FarmerColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _CropsGrid(
                    isDark: isDark,
                    refreshKey: _cropRefreshKey,
                    onTapCrop: (crop) async {
                      await Navigator.pushNamed(context, '/calendar');
                      if (mounted) setState(() { _cropRefreshKey++; });
                    },
                  ),
                ),

                const SizedBox(height: 26),

                // 5. Recent Leaf Scans (Diagnosed Crops Feed with friendly empty state)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('recent_scans'),
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('recent_scans_subtitle'),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: mutedTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        color: FarmerColors.primary,
                        tooltip: context.tr('view_history_tooltip'),
                        onPressed: () => Navigator.pushNamed(context, '/history'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FutureBuilder<List<Diagnosis>>(
                    future: service.fetchDiagnosisHistory(),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return _EmptyScansCard(
                          isDark: isDark,
                          onScanTap: () => Navigator.pushNamed(context, '/capture'),
                        );
                      }

                      return Column(
                        children: items.take(4).map((diag) {
                          final stage = diag.severityStage?.code ?? 'G0';
                          final disease = diag.predictedDisease ?? 'Healthy Leaf';
                          final damage = diag.severityPercent ?? (stage == 'G0' ? 0.0 : 15.0);
                          final conf = diag.confidence ?? 0.92;
                          final treatment = diag.treatmentRecommendation ??
                              'Optimal leaf canopy. Continue standard bio-fertilizer schedule.';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _FarmerDiagnosedCard(
                              cropName: disease.split('___')[0],
                              diseaseName: disease.contains('___')
                                  ? disease.split('___')[1].replaceAll('_', ' ')
                                  : disease,
                              stageCode: stage,
                              stageLabel: diag.severityStage?.label ?? 'Botanical Assessment',
                              confidence: conf,
                              leafDamage: damage,
                              prescribedTreatment: treatment,
                              scannedTime: diag.createdAt != null
                                  ? '${diag.createdAt!.day}/${diag.createdAt!.month} at ${diag.createdAt!.hour}:${diag.createdAt!.minute.toString().padLeft(2, '0')}'
                                  : 'Recent Scan',
                              isDark: isDark,
                              onAskAI: () {
                                Navigator.pushNamed(
                                  context,
                                  '/assistant',
                                  arguments: {
                                    'diagnosisContext':
                                        'Crop: ${disease.split('___')[0]}\nCondition: $disease\nStage: $stage\nTreatment: $treatment',
                                  },
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating "Ask AI Agronomist" Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/assistant'),
        backgroundColor: isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight,
        foregroundColor: FarmerColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FarmerRadius.pill),
          side: BorderSide(
            color: FarmerColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        icon: const Icon(Icons.smart_toy_rounded, size: 22, color: FarmerColors.primary),
        label: Text(
          context.tr('ask_ai_doctor'),
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: FarmerColors.primary,
          ),
        ),
      ),
      // 4-Tab Bottom Navigation Dock with Raised Center Scan Button
      bottomNavigationBar: _FarmerBottomDock(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 1) Navigator.pushNamed(context, '/calendar');
          if (index == 2) Navigator.pushNamed(context, '/capture');
          if (index == 3) Navigator.pushNamed(context, '/history');
        },
        isDark: isDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Components for Clean Farmer UX
// ─────────────────────────────────────────────────────────────────────────────

/// Big Hero "Scan Crop Leaf" Action Card
class _HeroScanCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _HeroScanCard({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32), // Forest Green
            Color(0xFF1B5E20), // Deep Earth Green
          ],
        ),
        borderRadius: BorderRadius.circular(FarmerRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.45 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FarmerRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                // Camera Icon Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Text Instruction
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('scan_title'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('scan_subtitle'),
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(FarmerRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('open_camera'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1B5E20)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's Farm Tasks Card (Actionable reminder)
class _TodayTasksCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onViewCalendar;

  const _TodayTasksCard({
    required this.isDark,
    required this.onViewCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final borderColor = isDark ? FarmerColors.borderDark : FarmerColors.borderLight;
    final textColor = isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FarmerRadius.lg),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: FarmerColors.warningAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule_rounded, size: 18, color: FarmerColors.warningAmber),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('today_tasks'),
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewCalendar,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${context.tr('nav_calendar')} ➔',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FarmerColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? FarmerColors.surfaceSubtle.withValues(alpha: 0.1) : FarmerColors.primaryLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FarmerColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: FarmerColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('today_task_sample_title'),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('today_task_sample_desc'),
                        style: TextStyle(fontSize: 12.5, color: mutedTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

/// 2-Column Monitored Crops Grid (Dynamically displays farmer's real planted crops)
class _CropsGrid extends StatefulWidget {
  final bool isDark;
  final int refreshKey;
  final ValueChanged<String> onTapCrop;

  const _CropsGrid({
    required this.isDark,
    required this.refreshKey,
    required this.onTapCrop,
  });

  @override
  State<_CropsGrid> createState() => _CropsGridState();
}

class _CropsGridState extends State<_CropsGrid> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SupabaseService>().fetchTrackedCrops();
  }

  @override
  void didUpdateWidget(_CropsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch whenever refreshKey changes (e.g. after adding a crop)
    if (oldWidget.refreshKey != widget.refreshKey) {
      _future = context.read<SupabaseService>().fetchTrackedCrops();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final borderColor = widget.isDark ? FarmerColors.borderDark : FarmerColors.borderLight;
    final textColor = widget.isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = widget.isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final tracked = snapshot.data ?? [];
        final List<Map<String, dynamic>> crops = [];

        if (tracked.isNotEmpty) {
          for (final item in tracked) {
            final cropName = item['crop_name'] as String? ?? 'Crop';
            final rawDate = item['planting_date'] as String?;
            DateTime plantingDate = DateTime.now();
            if (rawDate != null) {
              try {
                plantingDate = DateTime.parse(rawDate);
              } catch (_) {}
            }
            final days = DateTime.now().difference(plantingDate).inDays;
            final stage = getCurrentGrowthStage(cropName, plantingDate);
            final stageName = stage?.stageName ?? 'Sowing & Planting';
            final emoji = getCropEmoji(cropName);

            // Calculate stage index
            final stages = cropGrowthCalendar[cropName];
            final stageIdx = stages == null
                ? 1
                : (stages.indexWhere((s) => s.stageName == stageName) + 1);
            final totalStages = stages?.length ?? 5;

            crops.add({
              'emoji': emoji,
              'name': cropName,
              'variety': 'Day $days • $stageName',
              'status': 'Stage $stageIdx of $totalStages',
              'isHealthy': true,
            });
          }
        } else {
          // Default sample crops if none tracked yet
          crops.addAll([
            {
              'emoji': '🍅',
              'name': 'Tomato',
              'variety': 'Roma VF • Day 52',
              'status': 'Attention (G2)',
              'isHealthy': false,
            },
            {
              'emoji': '🥔',
              'name': 'Potato',
              'variety': 'Kufri Jyoti • Day 38',
              'status': 'Healthy (G0)',
              'isHealthy': true,
            },
            {
              'emoji': '🌽',
              'name': 'Corn',
              'variety': 'Sweet Horizon • Day 45',
              'status': 'Optimal (G0)',
              'isHealthy': true,
            },
            {
              'emoji': '🍇',
              'name': 'Grape',
              'variety': 'Thompson • Day 74',
              'status': 'Mild Spot (G1)',
              'isHealthy': false,
            },
          ]);
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: crops.length,
          itemBuilder: (context, index) {
            final c = crops[index];
            final isHealthy = c['isHealthy'] as bool;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onTapCrop(c['name'] as String),
                borderRadius: BorderRadius.circular(FarmerRadius.lg),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(FarmerRadius.lg),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            c['emoji'] as String,
                            style: const TextStyle(fontSize: 26),
                          ),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: isHealthy ? FarmerColors.healthyGreen : FarmerColors.warningAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (ctx) {
                            final rawName = c['name'] as String;
                            final cropKey = 'crop_${rawName.toLowerCase()}';
                            final localized = ctx.tr(cropKey);
                            final displayCropName = localized != cropKey ? localized : rawName;
                            return Text(
                              displayCropName,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }),
                          const SizedBox(height: 2),
                          Text(
                            c['variety'] as String,
                            style: TextStyle(fontSize: 11.5, color: mutedTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isHealthy
                              ? FarmerColors.healthyBg
                              : FarmerColors.warningBg,
                        borderRadius: BorderRadius.circular(FarmerRadius.sm),
                      ),
                      child: Text(
                        isHealthy
                            ? '${context.tr('healthy')} (G0)'
                            : '${context.tr('attention')} (G2)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isHealthy
                              ? FarmerColors.healthyGreen
                              : FarmerColors.warningAmber,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    );
  }
}

/// Friendly Empty State when there are no scans yet
class _EmptyScansCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onScanTap;

  const _EmptyScansCard({
    required this.isDark,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final textColor = isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FarmerRadius.lg),
        border: Border.all(
          color: isDark ? FarmerColors.borderDark : FarmerColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: FarmerColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, size: 36, color: FarmerColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('no_scans'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('no_scans_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: mutedTextColor, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onScanTap,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: Text(context.tr('scan_first')),
            style: FilledButton.styleFrom(
              backgroundColor: FarmerColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FarmerRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// High-contrast Diagnosed Card for Farmer Feed
class _FarmerDiagnosedCard extends StatelessWidget {
  final String cropName;
  final String diseaseName;
  final String stageCode;
  final String stageLabel;
  final double confidence;
  final double leafDamage;
  final String prescribedTreatment;
  final String scannedTime;
  final bool isDark;
  final VoidCallback onAskAI;

  const _FarmerDiagnosedCard({
    required this.cropName,
    required this.diseaseName,
    required this.stageCode,
    required this.stageLabel,
    required this.confidence,
    required this.leafDamage,
    required this.prescribedTreatment,
    required this.scannedTime,
    required this.isDark,
    required this.onAskAI,
  });

  Color _severityColor(String code) {
    switch (code) {
      case 'G0':
        return FarmerColors.healthyGreen;
      case 'G1':
        return FarmerColors.warningAmber;
      case 'G2':
        return const Color(0xFFE65100);
      case 'G3':
      default:
        return FarmerColors.alertRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sevColor = _severityColor(stageCode);
    final cardBg = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final borderColor = isDark ? FarmerColors.borderDark : FarmerColors.borderLight;
    final textColor = isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FarmerRadius.lg),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with crop tag, time, and severity stage
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FarmerColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cropName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: FarmerColors.primaryDeep,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scannedTime,
                          style: TextStyle(fontSize: 12, color: mutedTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(FarmerRadius.sm),
                    border: Border.all(color: sevColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: sevColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        stageCode,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: sevColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          stageLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: sevColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              diseaseName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Side-by-Side Damage & Confidence Gauges
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? FarmerColors.surfaceSubtle.withValues(alpha: 0.1) : FarmerColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: CustomPaint(
                            painter: _RadialGaugePainter(
                              percent: leafDamage / 100,
                              trackColor: borderColor,
                              progressColor: sevColor,
                              strokeWidth: 4,
                            ),
                            child: Center(
                              child: Text(
                                '${leafDamage.toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LEAF DAMAGE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: mutedTextColor,
                                ),
                              ),
                              Text(
                                '${leafDamage.toStringAsFixed(1)}% area',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: sevColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? FarmerColors.surfaceSubtle.withValues(alpha: 0.1) : FarmerColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: CustomPaint(
                            painter: _RadialGaugePainter(
                              percent: confidence,
                              trackColor: borderColor,
                              progressColor: FarmerColors.primary,
                              strokeWidth: 4,
                            ),
                            child: Center(
                              child: Text(
                                '${(confidence * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACCURACY',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: mutedTextColor,
                                ),
                              ),
                              Text(
                                '${(confidence * 100).toInt()}% match',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: FarmerColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Prescribed Treatment Callout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FarmerColors.warningAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FarmerColors.warningAmber.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 18, color: FarmerColors.warningAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECOMMENDED REMEDY',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: FarmerColors.warningAmber,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prescribedTreatment,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ask AI Button Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onAskAI,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: FarmerColors.primary),
                  label: Text(
                    context.tr('ask_ai_about_this'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FarmerColors.primary,
                    ),
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

class _RadialGaugePainter extends CustomPainter {
  final double percent;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RadialGaugePainter({
    required this.percent,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * percent.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

/// 4-Tab Farmer Bottom Dock with Raised Center Scan Button
class _FarmerBottomDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _FarmerBottomDock({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final borderColor = isDark ? FarmerColors.borderDark : FarmerColors.borderLight;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: isDark ? FarmerColors.bgDark : FarmerColors.bgLight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? bottomPad : 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(FarmerRadius.xl),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home Tab
              _DockTab(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: context.tr('nav_home'),
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              // 2. Calendar Tab
              _DockTab(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
                label: context.tr('nav_calendar'),
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              // 3. Raised Center Scan Button
              GestureDetector(
                onTap: () => onTap(2),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(FarmerRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('nav_capture'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 4. History Tab
              _DockTab(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: context.tr('nav_history'),
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FarmerColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(FarmerRadius.pill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? FarmerColors.primary : FarmerColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? FarmerColors.primaryDeep : FarmerColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
