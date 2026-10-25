import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  static const String _appVersion = '0.1.0';

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final themeProvider = context.watch<ThemeProvider>();
    final email = service.currentUser?.email ?? 'Not signed in';
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GradientAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Profile header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.canopy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _SettingsDivider(),
          const _SettingsSectionLabel('Preferences'),
          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.wb_sunny_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              isDark ? 'Using dark theme' : 'Using light theme',
              style: const TextStyle(fontSize: 12.5),
            ),
            value: isDark,
            activeThumbColor: AppColors.canopy,
            activeTrackColor: isDark ? AppColors.neon : null,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Reminder notifications'),
            subtitle: const Text(
              'Get notified about crop calendar reminders',
              style: TextStyle(fontSize: 12.5),
            ),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          const _SettingsDivider(),
          const _SettingsSectionLabel('Data'),
          ListTile(
            leading: Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Diagnosis history'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_month_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Crop calendar'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.pushNamed(context, '/calendar'),
          ),
          const _SettingsDivider(),
          const _SettingsSectionLabel('About'),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('App version'),
            trailing: Text(
              _appVersion,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.eco_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('About CropVision'),
            subtitle: const Text(
              'AI-powered crop disease detection with real-time severity staging.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          const _SettingsDivider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () async {
                await service.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rust,
                side: const BorderSide(color: AppColors.rust),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String text;
  const _SettingsSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
    );
  }
}
