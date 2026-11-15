import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/diagnosis.dart';

/// Thin wrapper around the Supabase client so screens never touch
/// `Supabase.instance` directly - makes it easy to swap/mocktest later.
class SupabaseService {
  final SupabaseClient? _injectedClient;

  SupabaseService([this._injectedClient]);

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // ---------- Auth ----------

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response =
        await _client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
      });
    }
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Requires Google configured under Authentication > Sign In /
  /// Providers > Google in the Supabase dashboard (Client ID + Secret
  /// from a Google Cloud OAuth app) before this will actually work -
  /// otherwise it opens the sign-in popup and then fails with a
  /// provider-not-enabled error.
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : 'cropvision://login-callback',
    );
  }

  /// Requires Apple configured under Authentication > Sign In /
  /// Providers > Apple in the Supabase dashboard (Services ID + Key
  /// from an Apple Developer account) before this will actually work.
  /// Note: "Sign in with Apple" is an Apple platform requirement for
  /// iOS App Store approval, but has no such requirement on Android -
  /// on Android this is included for parity with the reference design
  /// but is optional to wire up if this app isn't shipping to iOS.
  Future<bool> signInWithApple() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? Uri.base.origin : 'cropvision://login-callback',
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  // ---------- Storage ----------

  /// Takes raw bytes (from image_picker's XFile.readAsBytes()) rather
  /// than a dart:io File - uploadBinary works identically on web,
  /// Android, and iOS, whereas the plain .upload(path, File) call
  /// requires a real filesystem File object that doesn't exist on web.
  Future<String> uploadLeafImage(Uint8List bytes) async {
    final userId = currentUser!.id;
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('leaf-images').uploadBinary(fileName, bytes);
    return _client.storage.from('leaf-images').getPublicUrl(fileName);
  }

  // ---------- Diagnoses ----------

  Future<void> saveDiagnosis(Diagnosis diagnosis) async {
    await _client
        .from('diagnoses')
        .insert(diagnosis.toInsertMap(currentUser!.id));
  }

  Future<List<Diagnosis>> fetchDiagnosisHistory() async {
    final data = await _client
        .from('diagnoses')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return (data as List).map((row) => Diagnosis.fromMap(row)).toList();
  }

  // ---------- Reminders ----------

  Future<void> addReminder({
    required String title,
    String? description,
    required DateTime date,
    bool isRecurring = false,
  }) async {
    await _client.from('reminders').insert({
      'user_id': currentUser!.id,
      'title': title,
      'description': description,
      'reminder_date': date.toIso8601String(),
      'is_recurring': isRecurring,
    });
  }

  Future<List<Map<String, dynamic>>> fetchReminders() async {
    final data = await _client
        .from('reminders')
        .select()
        .eq('user_id', currentUser!.id)
        .order('reminder_date');
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------- Chat / AI assistant ----------

  Future<void> saveChatMessage(String role, String content) async {
    await _client.from('chat_messages').insert({
      'user_id': currentUser!.id,
      'role': role,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory() async {
    final data = await _client
        .from('chat_messages')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Direct client-side call to Google's Gemini API - chosen because
  /// it offers a genuinely free tier (no credit card needed to get an
  /// API key), unlike OpenAI which requires adding billing credits
  /// even for cheap models. Same trade-offs as before: API key lives
  /// in app code (fine for a student demo), and this may fail on
  /// Chrome/web due to CORS but works fine on native Android/iOS.
  Future<String> askAssistant(
    String message, {
    String? diagnosisContext,
    String language = 'English',
    String langCode = 'en',
  }) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      return _getLocalizedOfflineFallback(message, language, langCode);
    }

    final systemPrompt =
        'You are a helpful assistant for a crop disease detection app used '
        'by farmers. Answer questions about crop diseases, treatment, '
        'prevention, and general farming practices. Keep answers concise '
        'and practical - farmers may be reading this on a phone in the '
        'field.'
        '${diagnosisContext != null ? '\n\nMost recent diagnosis for this farmer: $diagnosisContext' : ''}\n\n'
        'CRITICAL: The user has selected their language as $language ($langCode). '
        'You MUST write your ENTIRE reply in $language, using clear and accurate terminology in that language.';

    // List of models to try in sequence if a model is unavailable (503), rate-limited (429), or deprecated
    final modelsToTry = [
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-2.5-flash',
      'gemini-1.5-pro',
      'gemini-3.6-flash',
    ];

    String lastError = '';

    for (final model in modelsToTry) {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await http.post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': '$systemPrompt\n\nFarmer\'s question: $message'}
                  ]
                }
              ],
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List?;
            if (candidates == null || candidates.isEmpty) {
              return 'No response generated.';
            }
            final parts = candidates[0]['content']['parts'] as List;
            return parts.isNotEmpty
                ? parts[0]['text'] as String
                : 'No response generated.';
          } else if (response.statusCode == 503 || response.statusCode == 429) {
            lastError = 'Gemini API temporary issue (${response.statusCode})';
            await Future.delayed(const Duration(milliseconds: 1000));
            continue;
          } else {
            lastError =
                'Gemini API error (${response.statusCode}): ${response.body}';
            break; // Try next model in list
          }
        } catch (e) {
          lastError = e.toString();
          break;
        }
      }
    }

    throw Exception(
        lastError.isNotEmpty ? lastError : 'Failed to reach Gemini API.');
  }

  /// Offline or local fallback advisory generator in the user's selected language
  String _getLocalizedOfflineFallback(
      String message, String language, String langCode) {
    switch (langCode) {
      case 'ta':
        return 'நான் உங்கள் பயிர் உதவியாளர். தற்போது ஆஃப்லைன் முறையில் இயங்குகிறேன்.\n\n'
            '• பயிர் நோய்களைக் கட்டுப்படுத்த பாதிக்கப்பட்ட இலைகளை உடனே அப்புறப்படுத்தவும்.\n'
            '• இலைகளில் ஈரம் தங்காமல் இருக்க சீரான இடைவெளி மற்றும் காற்றோட்டம் பராமரிக்கவும்.\n'
            '• பூஞ்சைத் தாக்குதலுக்குப் பரிந்துரைக்கப்பட்ட செம்பு மருந்தைப் பயன்படுத்தவும்.\n\n'
            'உங்கள் கேள்வி: "$message"\nமுழு விவரங்களுக்கு இணைய இணைப்பைச் சரிபார்க்கவும்.';
      case 'hi':
        return 'मैं आपका CropVision फसल सलाहकार हूँ। वर्तमान में ऑफलाइन मोड में सक्रिय हूँ।\n\n'
            '• बीमारी को फैलने से रोकने के लिए प्रभावित पत्तियों को तुरंत तोड़कर नष्ट कर दें।\n'
            '• पत्तियों पर पानी के जमाव से बचें और पौधों के बीच उचित दूरी बनाए रखें।\n'
            '• कवक जनित रोगों के लिए अनुशंसित कॉपर युक्त कवकनाशी का छिड़काव करें।\n\n'
            'आपका सवाल: "$message"\nविस्तृत जानकारी के लिए इंटरनेट कनेक्शन जांचें।';
      case 'te':
        return 'నేను మీ CropVision పంట సహాయకుడిని. ప్రస్తుతం ఆఫ్‌లైన్ విధానంలో పని చేస్తున్నాను.\n\n'
            '• వ్యాధి వ్యాప్తిని అరికట్టడానికి తెగులు సోకిన ఆకులను వెంటనే తొలగించండి.\n'
            '• ఆకులపై నీరు నిల్వ ఉండకుండా తగినంత గాలి ప్రసరణ ఉండేలా చూసుకోండి.\n'
            '• శిలీంధ్ర తెగుళ్ల నియంత్రణకు సిఫార్సు చేయబడిన రాగి శిలీంధ్రనాశిని పిచికారీ చేయండి.\n\n'
            'మీ ప్రశ్న: "$message"\nపూర్తి వివరాల కోసం ఇంటర్నెట్ కనెక్షన్ తనిఖీ చేయండి.';
      case 'mr':
        return 'मी तुमचा CropVision पीक सल्लागार आहे. सध्या ऑफलाइन मोडमध्ये कार्यरत आहे.\n\n'
            '• रोगाचा प्रादुर्भाव वाढू नये म्हणून बाधित पाने त्वरित काढून नष्ट करा.\n'
            '• पानांवर पाणी साचू देऊ नका आणि झाडांमध्ये योग्य अंतर ठेवा.\n'
            '• बुरशीजन्य रोगांसाठी शिफारस केलेल्या कॉपर बुरशीनाशकाची फवारणी करा.\n\n'
            'तुमचा प्रश्न: "$message"\nअधिक सविस्तर माहितीसाठी इंटरनेट कनेक्शन तपासा.';
      case 'kn':
        return 'ನಾನು ನಿಮ್ಮ CropVision ಬೆಳೆ ಸಹಾಯಕ. ಪ್ರಸ್ತುತ ಆಫ್‌ಲೈನ್ ಮೋಡ್‌ನಲ್ಲಿ ಕಾರ್ಯನಿರ್ವಹಿಸುತ್ತಿದ್ದೇನೆ.\n\n'
            '• ರೋಗ ಹರಡುವಿಕೆಯನ್ನು ತಡೆಯಲು ಬಾಧಿತ ಎಲೆಗಳನ್ನು ಕೂಡಲೇ ಕಿತ್ತು ನಾಶಪಡಿಸಿ.\n'
            '• ಎಲೆಗಳ ಮೇಲೆ ನೀರು ನಿಲ್ಲದಂತೆ ಸಸಿಗಳ ನಡುವೆ ಸೂಕ್ತ ಗಾಳಿ ಸಂಚಾರವಿರಲಿ.\n'
            '• ಶಿಲೀಂಧ್ರ ರೋಗಗಳ ನಿಯಂತ್ರಣಕ್ಕಾಗಿ ಶಿಫಾರಸು ಮಾಡಿದ ತಾಮ್ರದ ಶಿಲೀಂಧ್ರನಾಶಕವನ್ನು ಸಿಂಪಡಿಸಿ.\n\n'
            'ನಿಮ್ಮ ಪ್ರಶ್ನೆ: "$message"\nಹೆಚ್ಚಿನ ವಿವರಗಳಿಗಾಗಿ ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.';
      case 'en':
      default:
        return 'I am your CropVision assistant operating in offline mode.\n\n'
            '• Promptly prune and dispose of infected leaves to stop disease spread.\n'
            '• Avoid overhead irrigation and ensure good ventilation between plants.\n'
            '• Apply recommended copper-based or systemic fungicide as appropriate.\n\n'
            'Query: "$message"\nFor full AI assistance, ensure your internet connection and API key are configured.';
    }
  }

  // ---------- Dashboard stats ----------

  /// Powers the new home-screen dashboard cards: total scans, how many
  /// came back healthy vs needing attention. Computed from the same
  /// diagnoses table history already uses - no new schema needed.
  Future<DashboardStats> fetchDashboardStats() async {
    final data = await _client
        .from('diagnoses')
        .select('severity_stage, is_valid_leaf')
        .eq('user_id', currentUser!.id);

    final rows = List<Map<String, dynamic>>.from(data);
    final validScans = rows.where((r) => r['is_valid_leaf'] == true).toList();
    final healthy = validScans.where((r) => r['severity_stage'] == 'G0').length;
    final needsAttention = validScans.length - healthy;

    return DashboardStats(
      totalScans: validScans.length,
      healthyCount: healthy,
      needsAttentionCount: needsAttention,
    );
  }

  /// Crop growth tracking - see lib/data/crop_growth_calendar.dart for
  /// why this is date-based rather than detected from the leaf photo.
  Future<List<Map<String, dynamic>>> fetchTrackedCrops() async {
    final data = await _client
        .from('crop_growth_tracking')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> fetchTrackedCrop(String cropName) async {
    final data = await _client
        .from('crop_growth_tracking')
        .select()
        .eq('user_id', currentUser!.id)
        .eq('crop_name', cropName)
        .order('created_at', ascending: false)
        .limit(1);
    final rows = List<Map<String, dynamic>>.from(data);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> addTrackedCrop(String cropName, DateTime plantingDate) async {
    await _client.from('crop_growth_tracking').insert({
      'user_id': currentUser!.id,
      'crop_name': cropName,
      'planting_date':
          plantingDate.toIso8601String().split('T')[0], // date only
    });
  }

  Future<void> deleteTrackedCrop(String id) async {
    await _client.from('crop_growth_tracking').delete().eq('id', id);
  }
}

class DashboardStats {
  final int totalScans;
  final int healthyCount;
  final int needsAttentionCount;

  const DashboardStats({
    required this.totalScans,
    required this.healthyCount,
    required this.needsAttentionCount,
  });
}
