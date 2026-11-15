import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'theme/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/capture/capture_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://eiggroddrqrxssbjvzue.supabase.co'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpZ2dyb2RkcnFyeHNzYmp2enVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwNjg5NTAsImV4cCI6MjEwNzY0NDk1MH0.B-su_qr0EyGS2H3I27zV0oPf2Tt5ZBeol0YQmvvC_iQ'),
  );

  runApp(const CropDiseaseApp());
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'CropVision',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: kSupportedLocales.values.toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final isDark = themeProvider.isDarkMode;
              return Container(
                color: isDark ? const Color(0xFF111815) : const Color(0xFFE8ECE6),
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: child ?? const SizedBox(),
                  ),
                ),
              );
            },
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/capture': (context) => const CaptureScreen(),
              '/result': (context) => const ResultScreen(),
              '/history': (context) => const HistoryScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/assistant': (context) => const AssistantScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
