import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/crystal_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header top bar with Field Dashboard title and actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Field Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Settings icon
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            color: iconColor,
                            iconSize: 22,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                                minWidth: 40, minHeight: 40),
                            tooltip: 'Settings',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                          // 2. Middle Icon: Light / Dark Mode Toggle Icon (Brightness / Sun / Moon)
                          IconButton(
                            icon: Icon(
                              isDark
                                  ? Icons.wb_sunny_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                            color: iconColor,
                            iconSize: 22,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                                minWidth: 40, minHeight: 40),
                            tooltip: isDark
                                ? 'Switch to Light Mode'
                                : 'Switch to Dark Mode',
                            onPressed: () => themeProvider.toggleTheme(),
                          ),
                          // 3. Logout icon
                          IconButton(
                            icon: const Icon(Icons.logout),
                            color: iconColor,
                            iconSize: 22,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                                minWidth: 40, minHeight: 40),
                            tooltip: 'Log out',
                            onPressed: () async {
                              await service.signOut();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FutureBuilder<DashboardStats>(
                  future: service.fetchDashboardStats(),
                  builder: (context, snapshot) {
                    return _HealthOverviewCard(
                        stats: snapshot.data, loading: !snapshot.hasData);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick actions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    _HeroActionCard(
                      icon: Icons.camera_alt,
                      label: 'Diagnose Leaf',
                      subtitle: 'Take or upload a photo for instant analysis',
                      color: AppColors.canopy,
                      onTap: () => Navigator.pushNamed(context, '/capture'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallActionCard(
                            icon: Icons.history,
                            label: 'History',
                            color: AppColors.rust,
                            onTap: () =>
                                Navigator.pushNamed(context, '/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallActionCard(
                            icon: Icons.calendar_month,
                            label: 'Calendar',
                            color: AppColors.chlorotic,
                            onTap: () =>
                                Navigator.pushNamed(context, '/calendar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallActionCard(
                            icon: Icons.smart_toy,
                            label: 'Assistant',
                            color: isDark ? AppColors.neon : AppColors.canopy,
                            onTap: () =>
                                Navigator.pushNamed(context, '/assistant'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthOverviewCard extends StatelessWidget {
  final DashboardStats? stats;
  final bool loading;
  const _HealthOverviewCard({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final total = stats?.totalScans ?? 0;
    final healthy = stats?.healthyCount ?? 0;
    final needsAttention = stats?.needsAttentionCount ?? 0;
    final healthyFraction = total == 0 ? 0.5 : healthy / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CrystalPanel(
      padding: const EdgeInsets.all(22),
      accent: isDark ? AppColors.neon : AppColors.canopy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                loading ? '—' : '$total',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 36),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'scans this season',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: loading
                  ? Container(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                    )
                  : Row(
                      children: [
                        if (healthy > 0)
                          Expanded(
                            flex: (healthyFraction * 100).round().clamp(1, 100),
                            child: Container(color: AppColors.canopy),
                          ),
                        if (needsAttention > 0)
                          Expanded(
                            flex: ((1 - healthyFraction) * 100)
                                .round()
                                .clamp(1, 100),
                            child: Container(color: AppColors.rust),
                          ),
                        if (total == 0)
                          Expanded(
                            child: Container(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightSurfaceElevated,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LegendDot(color: AppColors.canopy, label: '$healthy healthy'),
              const SizedBox(width: 20),
              _LegendDot(
                  color: AppColors.rust,
                  label: '$needsAttention needs attention'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HeroActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon,
                size: 140, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.25)
              : color.withValues(alpha: 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
