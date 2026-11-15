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
  static const String demoUserId = '5f6b453d-7db7-4587-8b64-48ddd9d2c5a4';
  String get currentUserId => currentUser?.id ?? demoUserId;
  final List<Diagnosis> _localDiagnoses = [];
  final List<Map<String, dynamic>> _localTrackedCrops = [];

  // ---------- Auth ----------

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (response.user != null) {
      await _client.from('profiles').upsert({
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
    final userId = currentUserId;
    final fileName =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _client.storage.from('leaf-images').uploadBinary(fileName, bytes);
      return _client.storage.from('leaf-images').getPublicUrl(fileName);
    } catch (_) {
      return '';
    }
  }

  // ---------- Diagnoses ----------

  Future<void> saveDiagnosis(Diagnosis diagnosis) async {
    _localDiagnoses.insert(0, diagnosis);
    try {
      if (currentUser != null) {
        await _client.from('diagnoses').insert(diagnosis.toInsertMap(currentUserId));
      }
    } catch (_) {}
  }

  Future<List<Diagnosis>> fetchDiagnosisHistory() async {
    try {
      if (currentUser != null) {
        final data = await _client
            .from('diagnoses')
            .select()
            .eq('user_id', currentUserId)
            .order('created_at', ascending: false);
        return (data as List).map((row) => Diagnosis.fromMap(row)).toList();
      }
    } catch (_) {}
    return _localDiagnoses;
  }

  // ---------- Reminders ----------

  Future<void> addReminder({
    required String title,
    String? description,
    required DateTime date,
    bool isRecurring = false,
  }) async {
    try {
      if (currentUser != null) {
        await _client.from('reminders').insert({
          'user_id': currentUserId,
          'title': title,
          'description': description,
          'reminder_date': date.toIso8601String(),
          'is_recurring': isRecurring,
        });
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchReminders() async {
    try {
      if (currentUser != null) {
        final data = await _client
            .from('reminders')
            .select()
            .eq('user_id', currentUserId)
            .order('reminder_date');
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return [];
  }

  // ---------- Chat / AI assistant ----------

  Future<void> saveChatMessage(String role, String content) async {
    try {
      if (currentUser != null) {
        await _client.from('chat_messages').insert({
          'user_id': currentUserId,
          'role': role,
          'content': content,
        });
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory() async {
    try {
      if (currentUser != null) {
        final data = await _client
            .from('chat_messages')
            .select()
            .eq('user_id', currentUserId)
            .order('created_at');
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return [];
  }

  /// Direct client-side call to Google's Gemini API - chosen because
  /// it offers a genuinely free tier (no credit card needed to get an
  /// API key), unlike OpenAI which requires adding billing credits
  /// even for cheap models. Same trade-offs as before: API key lives
  /// in app code (fine for a student demo), and this may fail on
  /// Chrome/web due to CORS but works fine on native Android/iOS.
  /// Direct client-side call to Google's Gemini API with multi-language
  /// awareness (Tamil, Hindi, Telugu, Marathi, Kannada, English)
  Future<String> askAssistant(String message,
      {String? diagnosisContext, String? language, String? langCode}) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    final currentLang = language ?? 'English';
    final currentCode = langCode ?? 'en';

    if (apiKey.isEmpty) {
      return _generateLocalAgronomyReply(message, diagnosisContext,
          language: currentLang, langCode: currentCode);
    }

    final farmerName = currentUser?.userMetadata?['full_name'] as String? ??
        currentUser?.email?.split('@')[0] ??
        'Farmer';

    final langInstruction = currentLang != 'English'
        ? '\n\nCRITICAL LANGUAGE REQUIREMENT: The farmer has chosen their app language as $currentLang ($currentCode). You MUST write your ENTIRE reply in $currentLang. Use accurate and warm agricultural terminology in $currentLang.'
        : '';

    final systemPrompt =
        'You are an intelligent, friendly AI assistant for CropVision, a crop disease detection app. '
        'The farmer you are speaking with is named $farmerName. '
        'Answer any questions helpfully, warmly, and accurately. You specialize in crops (Tomato, Potato, Corn, Apple, Grape), '
        'disease identification, prevention, fungicides, organic remedies, and general farming practices. '
        'You can also answer questions about the user ($farmerName) and general inquiries politely and concisely.'
        '${diagnosisContext != null ? '\n\nMost recent diagnosis for this farmer: $diagnosisContext' : ''}'
        '$langInstruction';

    // Valid Gemini REST API model IDs — fastest first
    final modelsToTry = [
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-8b',
      'gemini-1.5-pro-latest',
    ];

    for (final model in modelsToTry) {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

      try {
        final response = await http.post(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemPrompt}
              ]
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': message}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 800,
            }
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            return _generateLocalAgronomyReply(message, diagnosisContext,
                language: currentLang, langCode: currentCode);
          }
          final parts = candidates[0]['content']['parts'] as List;
          return parts.isNotEmpty
              ? parts[0]['text'] as String
              : _generateLocalAgronomyReply(message, diagnosisContext,
                  language: currentLang, langCode: currentCode);
        } else if (response.statusCode == 429 || response.statusCode == 503) {
          // Overloaded — try next model immediately
          continue;
        } else {
          // Bad key or unsupported model — try next
          continue;
        }
      } catch (_) {
        continue; // network error or timeout — try next model
      }
    }

    // All models failed → rich local fallback in farmer's language
    return _generateLocalAgronomyReply(message, diagnosisContext,
        language: currentLang, langCode: currentCode);
  }

  // ---------- Dashboard stats ----------

  /// Powers the new home-screen dashboard cards: total scans, how many
  /// came back healthy vs needing attention. Computed from the same
  /// diagnoses table history already uses - no new schema needed.
  Future<DashboardStats> fetchDashboardStats() async {
    try {
      if (currentUser != null) {
        final data = await _client
            .from('diagnoses')
            .select('severity_stage, is_valid_leaf')
            .eq('user_id', currentUserId);

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
    } catch (_) {}

    final validScans = _localDiagnoses.where((d) => d.isValidLeaf).toList();
    final healthy = validScans.where((d) => d.severityStage == SeverityStage.g0).length;
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
    try {
      if (currentUser != null) {
        final data = await _client
            .from('crop_growth_tracking')
            .select()
            .eq('user_id', currentUserId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return _localTrackedCrops;
  }

  Future<void> addTrackedCrop(String cropName, DateTime plantingDate) async {
    final newCrop = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'crop_name': cropName,
      'planting_date': plantingDate.toIso8601String().split('T')[0],
    };
    _localTrackedCrops.insert(0, newCrop);
    try {
      if (currentUser != null) {
        await _client.from('crop_growth_tracking').insert({
          'user_id': currentUserId,
          'crop_name': cropName,
          'planting_date': plantingDate.toIso8601String().split('T')[0], // date only
        });
      }
    } catch (_) {}
  }

  Future<void> deleteTrackedCrop(String id) async {
    _localTrackedCrops.removeWhere((c) => c['id'] == id);
    try {
      if (currentUser != null) {
        await _client.from('crop_growth_tracking').delete().eq('id', id);
      }
    } catch (_) {}
  }

  /// Public helper — called by AssistantScreen when the AI API is completely
  /// unreachable and the screen navigated here with a diagnosis context string.
  /// Parses the context string and builds a formatted agronomy advice reply.
  String buildOfflineContextReply(String diagnosisContext) {
    final lower = diagnosisContext.toLowerCase();

    String disease = 'Unknown Disease';
    String stage = 'Unknown Stage';

    // Parse disease name from context string
    final diseaseMatch =
        RegExp(r'Disease:\s*([^|]+)').firstMatch(diagnosisContext);
    if (diseaseMatch != null) disease = diseaseMatch.group(1)!.trim();

    // Parse severity stage
    final stageMatch =
        RegExp(r'Severity:\s*([^(]+)').firstMatch(diagnosisContext);
    if (stageMatch != null) stage = stageMatch.group(1)!.trim();

    String advice = '';
    if (lower.contains('tomato') && lower.contains('early blight')) {
      advice = '**Tomato Early Blight Treatment**:\n'
          '• Remove all infected lower leaves immediately\n'
          '• Spray Copper Oxychloride (3g/L) or Chlorothalonil every 7 days\n'
          '• Mulch soil around base to prevent soil splash\n'
          '• Water at root level only — never wet foliage\n'
          '• If G3 (Critical): Apply Azoxystrobin systemic fungicide';
    } else if (lower.contains('tomato') && lower.contains('late blight')) {
      advice = '**Tomato Late Blight Treatment**:\n'
          '• Act immediately — this disease spreads very fast!\n'
          '• Apply Metalaxyl + Mancozeb every 5 days\n'
          '• Remove and bag all infected plant material\n'
          '• If G3 (Critical): Apply Cymoxanil. Remove severely infected plants.';
    } else if (lower.contains('tomato')) {
      advice = '**Tomato Disease Treatment**:\n'
          '• Apply copper-based fungicide every 7–10 days\n'
          '• Remove infected leaves and improve plant spacing\n'
          '• Water at base only; avoid wetting foliage overnight';
    } else if (lower.contains('potato')) {
      advice = '**Potato Disease Treatment**:\n'
          '• Apply Mancozeb preventatively every 7 days\n'
          '• For Late Blight: Use Metalaxyl-M immediately\n'
          '• Practice 3-year crop rotation away from tomatoes/peppers';
    } else if (lower.contains('corn') || lower.contains('maize')) {
      advice = '**Corn Disease Treatment**:\n'
          '• Apply triazole-based foliar fungicide\n'
          '• Use disease-resistant hybrid varieties for next season\n'
          '• Till crop residue after harvest to reduce spore load';
    } else if (lower.contains('apple')) {
      advice = '**Apple Disease Treatment**:\n'
          '• Apply Captan or Myclobutanil every 7–10 days\n'
          '• Prune for maximum airflow and sunlight penetration\n'
          '• Rake and destroy fallen leaves in autumn';
    } else if (lower.contains('grape')) {
      advice = '**Grape Disease Treatment**:\n'
          '• Apply Myclobutanil or Copper hydroxide\n'
          '• Open vine canopy with summer pruning\n'
          '• Spray preventatively every 10–14 days during wet season';
    } else {
      advice = '• Apply appropriate fungicide for the diagnosed disease\n'
          '• Remove and dispose of infected plant material\n'
          '• Improve spacing and airflow around plants\n'
          '• Water at root base only; avoid wetting leaves';
    }

    return '🔍 **Diagnosis Analysis: $disease**\n\n'
        '📊 **Severity**: $stage\n\n'
        '💊 **Recommended Actions**:\n$advice\n\n'
        '🛡️ **General Prevention**:\n'
        '• Rotate crops every season\n'
        '• Use certified disease-free planting material\n'
        '• Scout fields weekly for early signs\n'
        '• Maintain proper plant nutrition (NPK balance)\n\n'
        '💬 Feel free to ask me more specific questions about treatment, spraying, or prevention!';
  }

  String _generateLocalAgronomyReply(String message, String? context,
      {String language = 'English', String langCode = 'en'}) {
    final q = message.toLowerCase().trim();
    final name = currentUser?.userMetadata?['full_name'] as String? ??
        currentUser?.email?.split('@')[0] ??
        'Farmer';

    final code = langCode.toLowerCase();

    // ──────────────────────────────────────────────────────────────────────────
    // TAMIL (தமிழ்)
    // ──────────────────────────────────────────────────────────────────────────
    if (code == 'ta' || language.toLowerCase().contains('tamil')) {
      if (q.contains('my name') || q.contains('who am i') || q.contains('என் பெயர்') || q.contains('யார்')) {
        return 'நீங்கள் **$name** (${currentUser?.email ?? ''}) ஆக உள்நுழைந்துள்ளீர்கள்! 👨‍🌾\n\nநான் உங்கள் பயிர் பார்வை AI விவசாய உதவியாளர். இன்று உங்களுக்கு எவ்வாறு உதவ முடியும்?';
      }
      if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q.contains('வணக்கம்') || q.length < 4) {
        return 'வணக்கம் $name! 👋 பயிர் பார்வைக்கு உங்களை வரவேற்கிறோம்.\n\nநான் உங்கள் AI விவசாய உதவியாளர். என்னிடம் எதையும் கேளுங்கள்:\n• பயிர் நோய்கள் (தக்காளி, உருளைக்கிழங்கு, சோளம், ஆப்பிள், திராட்சை)\n• சிகிச்சை & தெளித்தல் அட்டவணைகள்\n• நீர்ப்பாசனம் & மண் பராமரிப்பு\n• தீவிர நிலைகள் (G0-G3)\n\nஉங்களுக்கு என்ன தகவல் தேவை? 🌱';
      }
      if (q.contains('thank') || q.contains('நன்றி')) {
        return 'மிக்க நன்றி, $name! 😊 மகிழ்ச்சியான விவசாயம்! 🌿\n\nஉங்கள் பயிர்கள் பற்றி எப்போது வேண்டுமானாலும் என்னிடம் கேட்கலாம்.';
      }
      if (q.contains('தக்காளி') || q.contains('tomato')) {
        return '🍅 **தக்காளி பயிர் பராமரிப்பு மற்றும் நோய் வழிகாட்டி**:\n\n'
            '• **ஆரம்ப கருகல் (Early Blight)**: கீழ் இலைகளில் அடர் பழுப்பு வளையப் புள்ளிகள். காப்பர் ஆக்ஸிகுளோரைடு (3g/L) அல்லது மேன்கோசெப் தெளிக்கவும்.\n'
            '• **பிற்கால கருகல் (Late Blight)**: நீர் கோர்த்த கரும் புள்ளிகள் & வெண் பூஞ்சை. மெட்டலாக்சில் + மேன்கோசெப் 7 நாட்களுக்கு ஒருமுறை தெளிக்கவும்.\n'
            '• **இலை சுருள் வைரஸ்**: வெள்ளை ஈக்களைக் கட்டுப்படுத்த வேப்பெண்ணெய் அல்லது இமிடாக்ளோப்ரிட் தெளிக்கவும்.\n\n'
            '**பராமரிப்பு**: காலையில் வேர் பகுதியில் நீர் பாய்ச்சவும். நல்ல காற்றோட்டத்தை பராமரிக்கவும்.';
      }
      if (q.contains('உருளை') || q.contains('potato')) {
        return '🥔 **உருளைக்கிழங்கு பயிர் பராமரிப்பு வழிகாட்டி**:\n\n'
            '• **பிற்கால கருகல் (Late Blight)**: மிகவும் தீவிரமான நோய். இலைகளில் கரும் புள்ளிகள் தென்பட்டால் உடனே மேன்கோசெப் தெளிக்கவும்.\n'
            '• சான்றளிக்கப்பட்ட விதை கிழங்குகளை மட்டுமே பயன்படுத்தவும்.\n'
            '• சரியான முறையில் மண் அணைத்து வடிகால் வசதியை உறுதி செய்யவும்.';
      }
      if (q.contains('சோளம்') || q.contains('corn') || q.contains('maize')) {
        return '🌽 **மக்காச்சோளம் பயிர் பராமரிப்பு வழிகாட்டி**:\n\n'
            '• **துரு நோய் & இலைக்கருகல்**: மேன்கோசெப் அல்லது அஸோக்ஸிஸ்ட்ரோபின் பூஞ்சாணக்கொல்லி தெளிக்கவும்.\n'
            '• படைப்புழு தாக்குதலைக் கண்காணிக்க இனக்கவர்ச்சி பொறிகளை அமைக்கவும்.\n'
            '• தழைச்சத்து உரங்களை சரியான பயிர் நிலைகளில் இடவும்.';
      }
      if (q.contains('திராட்சை') || q.contains('grape')) {
        return '🍇 **திராட்சை பயிர் பராமரிப்பு வழிகாட்டி**:\n\n'
            '• **சாம்பல் நோய் (Powdery Mildew)**: நனையும் கந்தகம் (Wettable Sulphur 2g/L) தெளிக்கவும்.\n'
            '• **கரும் அழுகல் (Black Rot)**: மேன்கோசெப் அல்லது போர்டோ கலவை தெளிக்கவும்.\n'
            '• கொடிகளுக்கு இடையே நல்ல காற்றோட்டம் மற்றும் சூரிய ஒளி கிடைப்பதை உறுதி செய்யவும்.';
      }
      if (q.contains('ஆப்பிள்') || q.contains('apple')) {
        return '🍎 **ஆப்பிள் பயிர் பராமரிப்பு வழிகாட்டி**:\n\n'
            '• **சொறி நோய் (Apple Scab)**: தளிர்ப்பு பருவத்தில் காப்பர் பூஞ்சாணக்கொல்லி தெளிக்கவும்.\n'
            '• உதிர்ந்த இலைகளை அகற்றி சுத்தமாக வைத்திருக்கவும்.';
      }
      return '🌱 வணக்கம் $name! நான் உங்கள் பயிர் பார்வை AI விவசாய உதவியாளர்.\n\n'
          'உங்கள் தக்காளி, உருளைக்கிழங்கு, சோளம், ஆப்பிள் மற்றும் திராட்சை பயிர்களின் நோய்கள், பூச்சி மேலாண்மை, தெளிப்பு அட்டவணை மற்றும் உரம் பற்றி என்னிடம் கேளுங்கள்!';
    }

    // ──────────────────────────────────────────────────────────────────────────
    // HINDI (हिंदी)
    // ──────────────────────────────────────────────────────────────────────────
    if (code == 'hi' || language.toLowerCase().contains('hindi')) {
      if (q.contains('my name') || q.contains('who am i') || q.contains('मेरा नाम') || q.contains('कौन')) {
        return 'आप **$name** (${currentUser?.email ?? ''}) के रूप में लॉग इन हैं! 👨‍🌾\n\nमैं आपका क्रॉपविज़न AI कृषि सहायक हूँ। आज मैं आपकी कैसे मदद कर सकता हूँ?';
      }
      if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q.contains('नमस्ते') || q.length < 4) {
        return 'नमस्ते $name! 👋 क्रॉपविज़न में आपका स्वागत है।\n\nमैं आपका AI कृषि सहायक हूँ। मुझसे पूछें:\n• फसल रोग (टमाटर, आलू, मक्का, सेब, अंगूर)\n• उपचार और छिड़काव कार्यक्रम\n• सिंचाई और मिट्टी की देखभाल\n• गंभीरता चरण (G0-G3)\n\nआप क्या जानना चाहते हैं? 🌱';
      }
      if (q.contains('thank') || q.contains('धन्यवाद') || q.contains('शुक्रिया')) {
        return 'आपका बहुत-बहुत धन्यवाद, $name! 😊 खुशहाल खेती! 🌿\n\nअपनी फसलों के बारे में कभी भी मुझसे पूछ सकते हैं।';
      }
      if (q.contains('टमाटर') || q.contains('tomato')) {
        return '🍅 **टमाटर फसल देखभाल एवं रोग नियंत्रण**:\n\n'
            '• **अगेती झुलसा (Early Blight)**: पत्तियों पर गोल छल्लेदार धब्बे। कॉपर ऑक्सीक्लोराइड या मैंकोज़ेब (2g/L) का छिड़काव करें।\n'
            '• **पछेती झुलसा (Late Blight)**: पत्तियों पर काले धब्बे और सफेद फफूंद। मेटालेक्सिल + मैंकोज़ेब का छिड़काव करें।\n'
            '• **पत्ती मरोड़ (Leaf Curl)**: सफेद मक्खी नियंत्रण के लिए इमिडाक्लोप्रिड या नीम तेल का छिड़काव करें।\n\n'
            '**सुझाव**: सुबह के समय केवल जड़ में पानी दें, पत्तियों को गीला न रखें।';
      }
      if (q.contains('आलू') || q.contains('potato')) {
        return '🥔 **आलू फसल देखभाल एवं रोग नियंत्रण**:\n\n'
            '• **पछेती झुलसा (Late Blight)**: तुरंत मैंकोज़ेब या मेटालेक्सिल का छिड़काव करें।\n'
            '• प्रमाणित एवं रोगमुक्त कंद ही बोएं।\n'
            '• उचित जल निकासी सुनिश्चित करें।';
      }
      return '🌱 नमस्ते $name! मैं आपका क्रॉपविज़न AI कृषि सहायक हूँ।\n\n'
          'टमाटर, आलू, मक्का, सेब और अंगूर की फसलों के रोगों, उपचार और खाद के बारे में मुझसे पूछें। मैं आपकी सहायता के लिए तैयार हूँ!';
    }

    // ──────────────────────────────────────────────────────────────────────────
    // TELUGU (తెలుగు)
    // ──────────────────────────────────────────────────────────────────────────
    if (code == 'te' || language.toLowerCase().contains('telugu')) {
      if (q.contains('hello') || q.contains('hi') || q.contains('నమస్కారం') || q.length < 4) {
        return 'నమస్కారం $name! 👋 క్రాప్‌విజన్‌కు స్వాగతం.\n\nనేను మీ AI వ్యవసాయ సహాయకుడిని. నన్ను అడగండి:\n• పంట తెగుళ్ళు (టమోటా, బంగాళాదుంప, మొక్కజొన్న, ఆపిల్, ద్రాక్ష)\n• పిచికారీ ప్రణాళికలు మరియు నివారణ\n• తీవ్రత దశలు (G0-G3)\n\nమీకు ఏ సమాచారం కావాలి? 🌱';
      }
      if (q.contains('టమోటా') || q.contains('tomato')) {
        return '🍅 **టమోటా పంట సంరక్షణ మరియు తెగులు నివారణ**:\n\n'
            '• **తొలి మచ్చల తెగులు (Early Blight)**: కాపర్ ఆక్సిక్లోరైడ్ లేదా మాంకోజెబ్ (2g/L) పిచికారీ చేయండి.\n'
            '• **చివరి మచ్చల తెగులు (Late Blight)**: మెటలాక్సిల్ + మాంకోజెబ్ 7 రోజులకు ఒకసారి పిచికారీ చేయండి.\n'
            '• **ఆకు ముడుత తెగులు**: తెల్లదోమ నివారణకు వేపనూనె లేదా ఇమిడాక్లోప్రిడ్ వాడండి.';
      }
      return '🌱 నమస్కారం $name! నేను మీ క్రాప్‌విజన్ AI వ్యవసాయ సహాయకుడిని. టమోటా, బంగాళాదుంప, మొక్కజొన్న, ఆపిల్ మరియు ద్రాక్ష పంటల సంరక్షణ గురించి నన్ను అడగండి!';
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARATHI (मराठी)
    // ──────────────────────────────────────────────────────────────────────────
    if (code == 'mr' || language.toLowerCase().contains('marathi')) {
      if (q.contains('hello') || q.contains('hi') || q.contains('नमस्कार') || q.length < 4) {
        return 'नमस्कार $name! 👋 क्रॉपव्हिजनमध्ये आपले स्वागत आहे.\n\nमी आपला AI शेती सहाय्यक आहे. मला विचारा:\n• पिकांचे रोग (टोमॅटो, बटाटा, मका, सफरचंद, द्राक्षे)\n• फवारणी वेळापत्रक आणि खत व्यवस्थापन\n• तीव्रता टप्पे (G0-G3)\n\nमी आपल्याला कशी मदत करू शकतो? 🌱';
      }
      return '🌱 नमस्कार $name! मी आपला क्रॉपव्हिजन AI शेती सहाय्यक आहे. टोमॅटो, बटाटा, मका, सफरचंद आणि द्राक्ष पिकांच्या रोगांबद्दल आणि उपायांबद्दल मला विचारा!';
    }

    // ──────────────────────────────────────────────────────────────────────────
    // KANNADA (ಕನ್ನಡ)
    // ──────────────────────────────────────────────────────────────────────────
    if (code == 'kn' || language.toLowerCase().contains('kannada')) {
      if (q.contains('hello') || q.contains('hi') || q.contains('ನಮಸ್ಕಾರ') || q.length < 4) {
        return 'ನಮಸ್ಕಾರ $name! 👋 ಕ್ರಾಪ್‌ವಿಷನ್‌ಗೆ ಸ್ವಾಗತ.\n\nನಾನು ನಿಮ್ಮ AI ಕೃಷಿ ಸಹಾಯಕ. ನನ್ನನ್ನು ಕೇಳಿ:\n• ಬೆಳೆ ರೋಗಗಳು (ಟೊಮೆಟೊ, ಆಲೂಗಡ್ಡೆ, ಜೋಳ, ಸೇಬು, ದ್ರಾಕ್ಷಿ)\n• ಸಿಂಪಡಣೆ ವೇಳಾಪಟ್ಟಿ ಮತ್ತು ಔಷಧಗಳು\n• ತೀವ್ರತೆಯ ಹಂತಗಳು (G0-G3)\n\nನಿಮಗೆ ಏನು ಮಾಹಿತಿ ಬೇಕು? 🌱';
      }
      return '🌱 ನಮಸ್ಕಾರ $name! ನಾನು ನಿಮ್ಮ ಕ್ರಾಪ್‌ವಿಷನ್ AI ಕೃಷಿ ಸಹಾಯಕ. ಬೆಳೆ ರೋಗಗಳು, ಕೀಟನಾಶಕಗಳು ಮತ್ತು ಗೊಬ್ಬರದ ಬಗ್ಗೆ ನನ್ನನ್ನು ಕೇಳಿ!';
    }

    // ──────────────────────────────────────────────────────────────────────────
    // DEFAULT ENGLISH
    // ──────────────────────────────────────────────────────────────────────────

    // ── Identity / profile ───────────────────────────────────────────────
    if (q.contains('my name') || q.contains('who am i') || q.contains('my profile') || q.contains('who i am')) {
      return 'You are logged in as **$name** (${currentUser?.email ?? ''})! 👨‍🌾\n\n'
          'I am your CropVision AI farming assistant. How can I help you today?';
    }

    if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q == 'hii' || q == 'h' || q.length < 4) {
      return 'Hello $name! 👋 Welcome to CropVision.\n\n'
          'I am your AI Agronomy Assistant. Ask me anything about:\n'
          '• Crop diseases (Tomato, Potato, Corn, Apple, Grape)\n'
          '• Treatment & spraying schedules\n'
          '• Watering & soil care\n'
          '• Diagnosis severity stages\n\n'
          'What would you like to know? 🌱';
    }

    if (q.contains('thank') || q.contains('thanks') || q.contains('great') || q.contains('good job')) {
      return 'You are welcome, $name! 😊 Happy farming! 🌿\n\n'
          'Feel free to ask me anything about your crops anytime.';
    }

    // ── Features / Help ──────────────────────────────────────────────────
    if (q.contains('what can you do') || q.contains('what you can do') || q.contains('features') ||
        q.contains('who are you') || q.contains('help') || q.contains('assist')) {
      return 'I am your **CropVision Agricultural AI Assistant**! 🌱\n\n'
          'Here\'s what I can help you with:\n'
          '• 🔍 **Disease ID**: Symptoms & causes for Tomato, Potato, Corn, Apple, Grape\n'
          '• 🩺 **Stage Treatment**: G1 (Mild) → G2 (Moderate) → G3 (Critical) care plans\n'
          '• 💧 **Spray Schedules**: Copper, Mancozeb, Chlorothalonil, Neem oil usage\n'
          '• 🌡️ **Weather Care**: Humidity, drought, and frost protection tips\n'
          '• 🪱 **Pest Control**: Common insects and integrated pest management\n'
          '• 🌱 **Soil & Water**: Fertilization, pH, irrigation best practices\n'
          '• 📅 **Growth Tracking**: Crop calendar and stage-based guidance\n\n'
          'Just ask me a question to get started!';
    }

    // ── Tomato diseases ──────────────────────────────────────────────────
    if (q.contains('tomato') && (q.contains('early blight') || q.contains('alternaria'))) {
      return '🍅 **Tomato Early Blight** (Alternaria solani):\n\n'
          '**Symptoms**: Dark brown concentric ring spots on lower/older leaves. Yellow halo around spots. Leaves yellow and drop.\n\n'
          '**Treatment by Stage**:\n'
          '• G1 (Mild): Remove infected leaves. Apply **Copper Oxychloride** (3g/L) or neem oil.\n'
          '• G2 (Moderate): Spray **Chlorothalonil** or **Mancozeb** every 7 days.\n'
          '• G3 (Critical): Apply **Azoxystrobin** systemic fungicide. Consider removing badly infected plants.\n\n'
          '**Prevention**: Mulch soil, water at root base, rotate crops each season.';
    }

    if (q.contains('tomato') && (q.contains('late blight') || q.contains('phytophthora'))) {
      return '🍅 **Tomato Late Blight** (Phytophthora infestans):\n\n'
          '**Symptoms**: Water-soaked dark patches on leaves that turn brown. White mold on underside. Spreads rapidly in wet cool weather.\n\n'
          '**Treatment by Stage**:\n'
          '• G1 (Mild): Apply **Copper hydroxide** preventatively. Improve air circulation.\n'
          '• G2 (Moderate): Spray **Metalaxyl + Mancozeb** every 5–7 days.\n'
          '• G3 (Critical): Emergency systemic treatment with **Cymoxanil**. Remove and bag all infected material.\n\n'
          '⚠️ Late blight spreads extremely fast. Act at first signs!';
    }

    if (q.contains('tomato') && (q.contains('yellow') || q.contains('mosaic') || q.contains('virus'))) {
      return '🍅 **Tomato Viral Diseases**:\n\n'
          '**Tomato Yellow Leaf Curl Virus (TYLCV)**: Yellowing, curled leaves, stunted growth. Spread by whiteflies.\n'
          '• Control whiteflies with **Imidacloprid** or yellow sticky traps.\n\n'
          '**Tomato Mosaic Virus (ToMV)**: Mosaic/mottled leaf patterns. Spread through touch and tools.\n'
          '• Disinfect tools with bleach (1:10). Remove infected plants.\n\n'
          '⚠️ No cure for viruses — focus on prevention and vector control!';
    }

    if (q.contains('tomato')) {
      return '🍅 **Tomato Crop Care Guide**:\n\n'
          '**Common Diseases**: Early Blight, Late Blight, Bacterial Spot, Fusarium Wilt, Leaf Curl Virus\n\n'
          '**Key Care Tips**:\n'
          '• Water at base early morning — never wet foliage at night\n'
          '• Stake plants and prune suckers for airflow\n'
          '• Apply calcium sprays to prevent blossom end rot\n'
          '• Spray copper fungicide preventatively every 10–14 days in humid weather\n\n'
          'Ask me specifically about Early Blight, Late Blight, or Yellow Leaf Curl for detailed treatment!';
    }

    // ── Potato diseases ──────────────────────────────────────────────────
    if (q.contains('potato') && q.contains('late blight')) {
      return '🥔 **Potato Late Blight** (Phytophthora infestans):\n\n'
          '⚠️ This is the most destructive potato disease — it caused the Irish Famine!\n\n'
          '**Symptoms**: Brown-black water-soaked lesions. White cottony mold on leaf undersides. Tubers rot.\n\n'
          '**Treatment**:\n'
          '• G1: Spray **Mancozeb** preventatively. Remove infected vines immediately.\n'
          '• G2: Apply **Metalaxyl-M + Mancozeb** systemically.\n'
          '• G3: Kill vines with haulm destruction. Harvest tubers only if disease-free.';
    }

    if (q.contains('potato')) {
      return '🥔 **Potato Crop Care Guide**:\n\n'
          '**Common Diseases**: Late Blight, Early Blight, Blackleg, Scab, Leaf Roll Virus\n\n'
          '**Key Care Tips**:\n'
          '• Plant certified disease-free seed tubers\n'
          '• Hill soil around stems to protect tubers from light and blight spores\n'
          '• Avoid overhead irrigation — use drip if possible\n'
          '• Practice 3-year rotation: never plant potatoes after tomatoes/peppers\n'
          '• Apply **Mancozeb** preventatively every 7–10 days in wet seasons\n\n'
          'Ask me about Late Blight or Early Blight for specific treatment plans!';
    }

    // ── Corn/Maize ───────────────────────────────────────────────────────
    if (q.contains('corn') || q.contains('maize')) {
      return '🌽 **Corn (Maize) Disease Guide**:\n\n'
          '**Common Rust** (Puccinia sorghi): Orange-brown pustules. Apply foliar triazole fungicide.\n\n'
          '**Northern Leaf Blight**: Long cigar-shaped grayish lesions. Apply fungicide before tasseling.\n\n'
          '**Gray Leaf Spot**: Rectangular tan lesions. Improve airflow; till crop residue after harvest.\n\n'
          '**Fall Armyworm**: Defoliation and silk damage. Use **Chlorpyrifos** or bio-control with Bt (Bacillus thuringiensis).\n\n'
          '**Prevention**: Use resistant hybrid varieties; maintain proper plant density (60,000–75,000 plants/ha).';
    }

    // ── Apple ────────────────────────────────────────────────────────────
    if (q.contains('apple') && q.contains('scab')) {
      return '🍎 **Apple Scab** (Venturia inaequalis):\n\n'
          '**Symptoms**: Olive-green to black velvety spots on leaves and fruit. Infected fruit cracks and deforms.\n\n'
          '**Treatment**:\n'
          '• Apply **Captan** or **Myclobutanil** starting at green-tip stage\n'
          '• Spray every 7–10 days during wet weather until petal fall\n'
          '• Switch to **Trifloxystrobin** if resistance develops\n\n'
          '**Prevention**: Rake and destroy fallen leaves in autumn. Prune for airflow.';
    }

    if (q.contains('apple')) {
      return '🍎 **Apple Orchard Care Guide**:\n\n'
          '**Common Diseases**: Apple Scab, Cedar Apple Rust, Fire Blight, Powdery Mildew, Brown Rot\n\n'
          '**Key Care Tips**:\n'
          '• Begin protective sprays at green-tip (bud break) in spring\n'
          '• Use Captan for scab, Streptomycin for fire blight\n'
          '• Remove mummified fruit and prune fire blight with sterile tools\n'
          '• Remove nearby juniper/cedar trees to break Cedar Apple Rust cycle\n\n'
          'Ask me about Apple Scab or Fire Blight for detailed treatment!';
    }

    // ── Grape ────────────────────────────────────────────────────────────
    if (q.contains('grape')) {
      return '🍇 **Grape Vineyard Care Guide**:\n\n'
          '**Black Rot**: Brown circular spots on leaves, shriveled black "mummies" on fruit. Spray **Myclobutanil** or **Captan**.\n\n'
          '**Downy Mildew**: Yellow oily spots topside, white downy growth underneath. Apply **Copper hydroxide** or **Metalaxyl**.\n\n'
          '**Powdery Mildew**: White powdery coating on shoots/leaves. Spray **Sulfur** or **Potassium Bicarbonate**.\n\n'
          '**Management**:\n'
          '• Open vine canopy with summer pruning for airflow\n'
          '• Apply preventative fungicide every 10–14 days during wet growing season\n'
          '• Avoid wetting foliage during irrigation';
    }

    // ── Spraying & Chemicals ─────────────────────────────────────────────
    if (q.contains('neem') || q.contains('organic') || q.contains('natural remedy')) {
      return '🌿 **Organic & Natural Remedies**:\n\n'
          '• **Neem Oil** (3–5 ml/L): Effective against fungal diseases (powdery mildew, early blight) and many insects. Apply weekly.\n'
          '• **Copper Fungicide**: For fungal and bacterial diseases. Safe for organic farming.\n'
          '• **Baking Soda Spray** (5g/L + dish soap): Quick home remedy for powdery mildew.\n'
          '• **Garlic Extract**: Natural insect repellent. Blend 2 bulbs in 1L water, strain, dilute 1:10.\n'
          '• **Compost Tea**: Boosts soil health and plant immunity.\n\n'
          '⚠️ Organic treatments require more frequent application (every 5–7 days) than chemical alternatives.';
    }

    if (q.contains('spray') || q.contains('fungicide') || q.contains('chemical') || q.contains('pesticide') || q.contains('insecticide')) {
      return '🧪 **Spraying & Chemical Safety Guide**:\n\n'
          '**Best Practices**:\n'
          '1. Spray early morning (6–9 AM) or late evening — avoids leaf scorch and protects bees\n'
          '2. Never spray when wind > 15 km/h or rain is expected within 4 hours\n'
          '3. Wear PPE: gloves, mask, goggles, and long-sleeved clothing\n\n'
          '**Fungicide Rotation** (prevents resistance):\n'
          '• Week 1: **Copper** (contact)\n'
          '• Week 2: **Mancozeb** (contact)\n'
          '• Week 3: **Azoxystrobin** (systemic)\n'
          '• Week 4: **Trifloxystrobin** (systemic)\n\n'
          '**Pre-Harvest Intervals (PHI)**: Always follow label — typically 7–21 days before harvest.';
    }

    // ── Watering / Irrigation ────────────────────────────────────────────
    if (q.contains('water') || q.contains('irrigat') || q.contains('drought')) {
      return '💧 **Irrigation & Watering Guide**:\n\n'
          '**Golden Rules**:\n'
          '• Water deeply but infrequently — promotes deep root growth\n'
          '• Always water at root base — wet foliage promotes fungal disease\n'
          '• Best time: Early morning (reduces evaporation and overnight leaf wetness)\n\n'
          '**By Crop**:\n'
          '• Tomato: 25–50 mm/week. Critical at flowering and fruit set.\n'
          '• Potato: 25–35 mm/week. Critical during tuber formation.\n'
          '• Corn: 25 mm/week. Critical from tasseling to dough stage.\n'
          '• Apple/Grape: Deep irrigation every 10–14 days during fruiting.\n\n'
          '**Drip Irrigation** is always preferred — saves water and keeps foliage dry!';
    }

    // ── Soil & Fertilizer ────────────────────────────────────────────────
    if (q.contains('soil') || q.contains('fertili') || q.contains('compost') || q.contains('nutrient') || q.contains('npk')) {
      return '🌍 **Soil & Fertilization Guide**:\n\n'
          '**pH Targets**:\n'
          '• Tomato/Potato: 6.0–6.8\n'
          '• Corn: 6.0–7.0\n'
          '• Apple: 6.0–7.0\n'
          '• Grape: 6.0–6.5\n\n'
          '**NPK Guide**:\n'
          '• **N (Nitrogen)**: Promotes leaf/stem growth — apply at planting and vegetative stage\n'
          '• **P (Phosphorus)**: Root and flower development — apply at planting\n'
          '• **K (Potassium)**: Fruit quality and disease resistance — apply at fruiting\n\n'
          '**Tip**: Add organic compost (5–10 t/ha) before planting to improve soil structure and microbial life.';
    }

    // ── Weather / Humidity ───────────────────────────────────────────────
    if (q.contains('weather') || q.contains('humidity') || q.contains('temperature') || q.contains('frost') || q.contains('heat')) {
      return '🌡️ **Weather & Crop Protection**:\n\n'
          '**Frost Protection**:\n'
          '• Cover plants with row covers or fleece when temp < 2°C\n'
          '• Water soil before frost — moist soil holds heat better\n'
          '• Avoid nitrogen fertilizer in late season (makes plants frost-sensitive)\n\n'
          '**High Humidity (>80%)**: Prime conditions for fungal disease!\n'
          '• Increase fungicide spray frequency to every 5–7 days\n'
          '• Improve airflow by pruning dense foliage\n\n'
          '**Heat Stress (>35°C)**:\n'
          '• Provide shade cloth (30–40%) for sensitive crops\n'
          '• Increase irrigation frequency\n'
          '• Avoid spraying chemicals in peak afternoon heat';
    }

    // ── Severity stages ──────────────────────────────────────────────────
    if (q.contains('stage') || q.contains('severity') || q.contains('g0') || q.contains('g1') || q.contains('g2') || q.contains('g3')) {
      return '📊 **CropVision Severity Stages Explained**:\n\n'
          '• **G0 — Healthy (0% leaf area affected)**\n'
          '  ✅ No disease. Maintain weekly monitoring & preventative sprays.\n\n'
          '• **G1 — Mild (<10% leaf area)**\n'
          '  🟡 Remove infected leaves. Apply protective copper/neem spray. Monitor closely.\n\n'
          '• **G2 — Moderate (10–30% leaf area)**\n'
          '  🟠 Active disease. Start chemical treatment program every 7–10 days. Improve airflow.\n\n'
          '• **G3 — Critical (>30% leaf area)**\n'
          '  🔴 Emergency! Apply systemic fungicide immediately. Consider removing worst-affected plants to protect neighbors.';
    }

    // ── First crop / beginners ───────────────────────────────────────────
    if (q.contains('beginner') || q.contains('first crop') || q.contains('start farming') || q.contains('new farmer')) {
      return '🌱 **Getting Started — Beginner\'s Guide**:\n\n'
          '**Best First Crops**: Tomatoes or Potatoes — fast-growing, high yield, fully supported by CropVision.\n\n'
          '**5 Steps to Success**:\n'
          '1. **Soil Prep**: Add organic compost, test pH (aim 6.0–6.8)\n'
          '2. **Spacing**: 45–60 cm between plants for airflow and sun\n'
          '3. **Watering**: Root-base only, early morning\n'
          '4. **Mulch**: Straw mulch around stem base (prevents soil-splash disease)\n'
          '5. **Scout Weekly**: Check leaf undersides for early disease signs\n\n'
          '📱 Use the **Calendar** tab in CropVision to track your crop\'s growth stages!';
    }

    // ── General / fallback ───────────────────────────────────────────────
    return '🌱 **CropVision AI Assistant** — Offline Mode\n\n'
        'Hi $name! I\'m currently in offline mode but can still help with:\n\n'
        '• 🍅 **Tomato** diseases (Early Blight, Late Blight, Viruses)\n'
        '• 🥔 **Potato** diseases (Late Blight, Early Blight, Scab)\n'
        '• 🌽 **Corn/Maize** (Rust, Northern Leaf Blight, Armyworm)\n'
        '• 🍎 **Apple** (Scab, Fire Blight, Cedar Rust)\n'
        '• 🍇 **Grape** (Black Rot, Downy Mildew, Powdery Mildew)\n'
        '• 💧 Watering, Soil, Fertilization tips\n'
        '• 🧪 Fungicide rotation & spraying schedules\n'
        '• 📊 G0/G1/G2/G3 severity stage treatment\n\n'
        'Ask me any of the above topics for detailed advice! 🌿';
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
