import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

const String kLocalePrefKey = 'selected_locale_code';

const Map<String, Locale> kSupportedLocales = {
  'en': Locale('en'),
  'hi': Locale('hi'),
  'ta': Locale('ta'),
  'te': Locale('te'),
  'mr': Locale('mr'),
  'bn': Locale('bn'),
  'gu': Locale('gu'),
  'pa': Locale('pa'),
  'es': Locale('es'),
  'sw': Locale('sw'),
};

const Map<String, String> kLanguageNativeNames = {
  'en': 'English',
  'hi': 'हिंदी (Hindi)',
  'ta': 'தமிழ் (Tamil)',
  'te': 'తెలుగు (Telugu)',
  'mr': 'मराठी (Marathi)',
  'bn': 'বাংলা (Bengali)',
  'gu': 'ગુજરાતી (Gujarati)',
  'pa': 'ਪੰਜਾਬੀ (Punjabi)',
  'es': 'Español (Spanish)',
  'sw': 'Kiswahili (Swahili)',
};

const Map<String, String> kLanguageEnglishNames = {
  'en': 'English',
  'hi': 'Hindi',
  'ta': 'Tamil',
  'te': 'Telugu',
  'mr': 'Marathi',
  'bn': 'Bengali',
  'gu': 'Gujarati',
  'pa': 'Punjabi',
  'es': 'Spanish',
  'sw': 'Swahili',
};

const Map<String, String> _kKeyAliases = {
  'File could not be read as an image.': 'err_file_not_image',
  'Image is too dark. Please retake in better lighting.': 'err_too_dark',
  'Image is overexposed. Please avoid direct glare/flash.': 'err_overexposed',
  'Image is too blurry. Please hold the camera steady and refocus.':
      'err_too_blurry',
  'No crop leaf detected in this image. Please photograph a leaf directly.':
      'err_no_leaf_detected',
  'Healthy': 'severity_g0',
  'Mild Infection': 'severity_g1',
  'Moderate Infection': 'severity_g2',
  'Critical Infection': 'severity_g3',
};

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

  String get currentLanguageCode => _locale.languageCode;

  String get currentLanguageName =>
      kLanguageNativeNames[_locale.languageCode] ?? 'English';

  String get currentLanguageEnglishName =>
      kLanguageEnglishNames[_locale.languageCode] ?? 'English';

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(kLocalePrefKey);
      if (savedCode != null && kSupportedLocales.containsKey(savedCode)) {
        _locale = kSupportedLocales[savedCode]!;
        notifyListeners();
      }
    } catch (_) {
      // Fallback to default locale
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!kSupportedLocales.containsKey(newLocale.languageCode)) return;
    if (_locale.languageCode == newLocale.languageCode) return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kLocalePrefKey, newLocale.languageCode);
    } catch (_) {}
  }

  Future<void> setLocaleCode(String code) async {
    final matched = kSupportedLocales[code];
    if (matched != null) {
      await setLocale(matched);
    }
  }

  String translate(String key) {
    final langCode = _locale.languageCode;
    final langMap = kAppTranslations[langCode];
    if (langMap != null && langMap.containsKey(key)) {
      return langMap[key]!;
    }
    // Check aliases in current language
    final aliasKey = _kKeyAliases[key];
    if (aliasKey != null && langMap != null && langMap.containsKey(aliasKey)) {
      return langMap[aliasKey]!;
    }
    // Safe fallback to English
    final enMap = kAppTranslations['en'];
    if (enMap != null && enMap.containsKey(key)) {
      return enMap[key]!;
    }
    if (aliasKey != null && enMap != null && enMap.containsKey(aliasKey)) {
      return enMap[aliasKey]!;
    }
    // If key not found anywhere, return the key itself
    return key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key, {bool listen = true}) {
    final provider = Provider.of<LocaleProvider>(this, listen: listen);
    return provider.translate(key);
  }
}

