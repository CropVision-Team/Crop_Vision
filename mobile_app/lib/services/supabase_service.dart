import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/diagnosis.dart';

/// Thin wrapper around the Supabase client so screens never touch
/// `Supabase.instance` directly - makes it easy to swap/mocktest later.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

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
  Future<String> askAssistant(String message,
      {String? diagnosisContext}) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      return 'API key not configured. Please set the GEMINI_API_KEY environment variable.';
    }

    final systemPrompt =
        'You are a helpful assistant for a crop disease detection app used '
        'by farmers. Answer questions about crop diseases, treatment, '
        'prevention, and general farming practices. Keep answers concise '
        'and practical - farmers may be reading this on a phone in the '
        'field.'
        '${diagnosisContext != null ? '\n\nMost recent diagnosis for this farmer: $diagnosisContext' : ''}';

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
