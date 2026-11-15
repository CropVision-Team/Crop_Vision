import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cropvision/l10n/locale_provider.dart';
import 'package:cropvision/l10n/app_translations.dart';
import 'package:cropvision/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider & Localization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('All 6 supported languages exist in kSupportedLocales and translations', () {
      expect(kSupportedLocales.keys, containsAll(['en', 'ta', 'hi', 'te', 'mr', 'kn']));
      expect(kAppTranslations.keys, containsAll(['en', 'ta', 'hi', 'te', 'mr', 'kn']));
    });

    test('Default locale is English', () {
      final provider = LocaleProvider();
      expect(provider.locale.languageCode, equals('en'));
      expect(provider.currentLanguageName, equals('English'));
      expect(provider.translate('app_name'), equals('CropVision'));
    });

    test('Switching locale changes translations immediately', () async {
      final provider = LocaleProvider();

      // Switch to Tamil
      await provider.setLocaleCode('ta');
      expect(provider.locale.languageCode, equals('ta'));
      expect(provider.currentLanguageName, contains('தமிழ்'));
      expect(provider.translate('field_dashboard'), equals('வயல் கட்டுப்பாட்டு பலகை'));

      // Switch to Hindi
      await provider.setLocaleCode('hi');
      expect(provider.locale.languageCode, equals('hi'));
      expect(provider.currentLanguageName, contains('हिंदी'));
      expect(provider.translate('field_dashboard'), equals('खेत डैशबोर्ड'));

      // Switch to Telugu
      await provider.setLocaleCode('te');
      expect(provider.locale.languageCode, equals('te'));
      expect(provider.currentLanguageName, contains('తెలుగు'));
      expect(provider.translate('field_dashboard'), equals('ఫీల్డ్ డ్యాష్‌బోర్డ్'));

      // Switch to Marathi
      await provider.setLocaleCode('mr');
      expect(provider.locale.languageCode, equals('mr'));
      expect(provider.currentLanguageName, contains('मराठी'));
      expect(provider.translate('field_dashboard'), equals('शेत डॅशबोर्ड'));

      // Switch to Kannada
      await provider.setLocaleCode('kn');
      expect(provider.locale.languageCode, equals('kn'));
      expect(provider.currentLanguageName, contains('ಕನ್ನಡ'));
      expect(provider.translate('field_dashboard'), equals('ಕ್ಷೇತ್ರ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್'));
    });

    test('Missing key safely falls back to English', () async {
      final provider = LocaleProvider();
      await provider.setLocaleCode('ta');

      // Test with an English key that might not exist in another language
      expect(provider.translate('app_name'), equals('CropVision'));

      // Non-existent key returns key itself
      expect(provider.translate('non_existent_key_123'), equals('non_existent_key_123'));
    });

    test('Key alias translation works for legacy strings', () async {
      final provider = LocaleProvider();
      await provider.setLocaleCode('hi');

      expect(
        provider.translate('Image is too dark. Please retake in better lighting.'),
        equals('छवि बहुत अंधेरी है। कृपया बेहतर रोशनी में फोटो लें।'),
      );
    });

    test('Locale persistence via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'selected_locale_code': 'mr'});
      final provider = LocaleProvider();
      // Wait for async constructor load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.locale.languageCode, equals('mr'));
    });
  });

  group('Multilingual AI Assistant Prompt & Fallback Tests', () {
    test('Offline fallback returns appropriate language response', () async {
      final service = SupabaseService();

      // When GEMINI_API_KEY is empty, it returns the localized offline fallback
      final taReply = await service.askAssistant(
        'What to do for leaf spot?',
        language: 'Tamil',
        langCode: 'ta',
      );
      expect(taReply, contains('பயிர்'));

      final hiReply = await service.askAssistant(
        'फसल में पत्ती पीली पड़ रही है',
        language: 'Hindi',
        langCode: 'hi',
      );
      expect(hiReply, contains('फसल'));

      final teReply = await service.askAssistant(
        'ఆకు మచ్చ తెగులు నివారణ',
        language: 'Telugu',
        langCode: 'te',
      );
      expect(teReply, contains('పంట'));

      final mrReply = await service.askAssistant(
        'पाने पिवळी पडत आहेत',
        language: 'Marathi',
        langCode: 'mr',
      );
      expect(mrReply, contains('पीक'));

      final knReply = await service.askAssistant(
        'ಎಲೆ ಕಲೆ ರೋಗ ನಿಯಂತ್ರಣ',
        language: 'Kannada',
        langCode: 'kn',
      );
      expect(knReply, contains('ಬೆಳೆ'));
    });
  });

  group('UI Dynamic Localization Update Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('UI immediately updates all labels when language changes without restart',
        (WidgetTester tester) async {
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<LocaleProvider>.value(
          value: localeProvider,
          child: Consumer<LocaleProvider>(
            builder: (context, lp, child) {
              return MaterialApp(
                locale: lp.locale,
                supportedLocales: kSupportedLocales.values.toList(),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: Scaffold(
                  body: Builder(
                    builder: (innerContext) {
                      return Column(
                        children: [
                          Text(innerContext.tr('field_dashboard')),
                          Text(innerContext.tr('diagnose_leaf')),
                          Text(innerContext.tr('settings')),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Verify initial English
      expect(find.text('Field Dashboard'), findsOneWidget);
      expect(find.text('Diagnose Leaf'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Switch to Tamil
      await localeProvider.setLocaleCode('ta');
      await tester.pumpAndSettle();
      expect(find.text('வயல் கட்டுப்பாட்டு பலகை'), findsOneWidget);
      expect(find.text('இலையை பரிசோதிக்கவும்'), findsOneWidget);
      expect(find.text('அமைப்புகள்'), findsOneWidget);

      // Switch to Hindi
      await localeProvider.setLocaleCode('hi');
      await tester.pumpAndSettle();
      expect(find.text('खेत डैशबोर्ड'), findsOneWidget);
      expect(find.text('पत्ती की जांच करें'), findsOneWidget);
      expect(find.text('सेटिंग्स'), findsOneWidget);

      // Switch to Telugu
      await localeProvider.setLocaleCode('te');
      await tester.pumpAndSettle();
      expect(find.text('ఫీల్డ్ డ్యాష్‌బోర్డ్'), findsOneWidget);
      expect(find.text('ఆకును పరీక్షించండి'), findsOneWidget);
      expect(find.text('సెట్టింగ్‌లు'), findsOneWidget);

      // Switch to Marathi
      await localeProvider.setLocaleCode('mr');
      await tester.pumpAndSettle();
      expect(find.text('शेत डॅशबोर्ड'), findsOneWidget);
      expect(find.text('पानाची तपासणी करा'), findsOneWidget);
      expect(find.text('सेटिंग्ज'), findsOneWidget);

      // Switch to Kannada
      await localeProvider.setLocaleCode('kn');
      await tester.pumpAndSettle();
      expect(find.text('ಕ್ಷೇತ್ರ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್'), findsOneWidget);
      expect(find.text('ಎಲೆಯನ್ನು ಪರೀಕ್ಷಿಸಿ'), findsOneWidget);
      expect(find.text('ಸೆಟ್ಟಿಂಗ್‌ಗಳು'), findsOneWidget);
    });
  });
}
