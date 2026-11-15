import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_design_system.dart';
import '../theme/theme_provider.dart';
import '../theme/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  static const String _appVersion = '2.1.0';

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final email = service.currentUser?.email ?? 'Farmer Account';
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? FarmerColors.textLight : FarmerColors.textDark;
    final mutedTextColor = isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted;
    final cardBg = isDark ? FarmerColors.surfaceDark : FarmerColors.surfaceLight;
    final borderColor = isDark ? FarmerColors.borderDark : FarmerColors.borderLight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GradientAppBar(title: localeProvider.tr('settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Farmer Profile Card
          Container(
            padding: const EdgeInsets.all(18),
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
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: FarmerColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: FarmerColors.primary, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localeProvider.tr('farmer_profile'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.contains('@') ? email : localeProvider.tr('farmer_account'),
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: FarmerColors.healthyBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          localeProvider.tr('sector_farmer'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FarmerColors.primaryDeep),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Language Selection Card
          _SectionHeader(title: localeProvider.tr('language_region'), isDark: isDark),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(FarmerRadius.lg),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FarmerColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.translate_rounded, color: FarmerColors.primary, size: 20),
              ),
              title: Text(localeProvider.tr('app_language'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
              subtitle: Text(localeProvider.languageName, style: TextStyle(color: mutedTextColor, fontSize: 13)),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: localeProvider.languageName,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14),
                  dropdownColor: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      localeProvider.setLanguage(newValue);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${localeProvider.tr('lang_switched')} $newValue'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: FarmerColors.primary,
                        ),
                      );
                    }
                  },
                  items: kSupportedLocales.keys.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Display & Reminders
          _SectionHeader(title: localeProvider.tr('preferences'), isDark: isDark),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(FarmerRadius.lg),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? FarmerColors.surfaceSubtle.withValues(alpha: 0.1) : FarmerColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                  title: Text(localeProvider.tr('dark_mode'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                  subtitle: Text(
                    isDark ? localeProvider.tr('dark_mode_active') : localeProvider.tr('light_mode_active'),
                    style: TextStyle(fontSize: 12.5, color: mutedTextColor),
                  ),
                  value: isDark,
                  activeThumbColor: Colors.white,
                  activeTrackColor: FarmerColors.primary,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
                Divider(height: 1, color: borderColor),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? FarmerColors.surfaceSubtle.withValues(alpha: 0.1) : FarmerColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.notifications_active_rounded, color: textColor, size: 20),
                  ),
                  title: Text(localeProvider.tr('farm_reminders'), style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                  subtitle: Text(
                    localeProvider.tr('farm_reminders_desc'),
                    style: TextStyle(fontSize: 12.5, color: mutedTextColor),
                  ),
                  value: _notificationsEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: FarmerColors.primary,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Technical / About Model (Relocated jargon for transparency)
          _SectionHeader(title: localeProvider.tr('about_tech'), isDark: isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(FarmerRadius.lg),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FarmerColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: FarmerColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(localeProvider.tr('tech_title'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                          Text(localeProvider.tr('tech_subtitle'), style: TextStyle(color: mutedTextColor, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  localeProvider.tr('tech_desc'),
                  style: TextStyle(fontSize: 13, height: 1.4, color: mutedTextColor),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TechChip(localeProvider.tr('chip_classes'), isDark: isDark),
                    _TechChip(localeProvider.tr('chip_severity'), isDark: isDark),
                    _TechChip(localeProvider.tr('chip_remedies'), isDark: isDark),
                    _TechChip('${localeProvider.tr('app_version')} $_appVersion', isDark: isDark),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 5. Sign Out Button
          OutlinedButton.icon(
            onPressed: () async {
              await service.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: FarmerColors.alertRed,
              side: const BorderSide(color: FarmerColors.alertRed, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FarmerRadius.md),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              localeProvider.tr('sign_out_btn'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? FarmerColors.textMutedDark : FarmerColors.textMuted,
        ),
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _TechChip(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? FarmerColors.surfaceSubtle.withValues(alpha: 0.15) : FarmerColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: FarmerColors.primaryDeep,
        ),
      ),
    );
  }
}
