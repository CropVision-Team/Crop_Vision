import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../l10n/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  static const String _appVersion = '0.1.0';

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('select_language')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: kSupportedLocales.keys.map((code) {
              final isSelected =
                  localeProvider.locale.languageCode == code;
              return ListTile(
                title: Text(
                  kLanguageNativeNames[code] ?? code,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.canopy : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.canopy)
                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () {
                  localeProvider.setLocaleCode(code);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final email = service.currentUser?.email ?? context.tr('not_signed_in');
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GradientAppBar(title: context.tr('settings')),
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
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('account'),
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
          _SettingsSectionLabel(context.tr('preferences')),
          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.wb_sunny_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(context.tr('dark_mode')),
            subtitle: Text(
              isDark
                  ? context.tr('using_dark_theme')
                  : context.tr('using_light_theme'),
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
            title: Text(context.tr('reminder_notifications')),
            subtitle: Text(
              context.tr('reminder_notifications_subtitle'),
              style: const TextStyle(fontSize: 12.5),
            ),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          ListTile(
            leading: Icon(
              Icons.language,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(context.tr('language')),
            subtitle: Text(
              localeProvider.currentLanguageName,
              style: const TextStyle(fontSize: 12.5),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showLanguageDialog(context),
          ),
          const _SettingsDivider(),
          _SettingsSectionLabel(context.tr('data')),
          ListTile(
            leading: Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(context.tr('diagnosis_history')),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_month_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(context.tr('crop_calendar')),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.pushNamed(context, '/calendar'),
          ),
          const _SettingsDivider(),
          _SettingsSectionLabel(context.tr('about')),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(context.tr('app_version')),
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
            title: Text(context.tr('about_cropvision')),
            subtitle: Text(
              context.tr('about_cropvision_desc'),
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          const _SettingsDivider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () async {
                await service.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rust,
                side: const BorderSide(color: AppColors.rust),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout),
              label: Text(context.tr('log_out')),
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
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.7),
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
      color: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightSurfaceElevated,
    );
  }
}
