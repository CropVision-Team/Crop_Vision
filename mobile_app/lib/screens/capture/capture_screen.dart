import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/supabase_service.dart';
import '../../services/image_verification_service.dart';
import '../../services/severity_estimation_service.dart';
import '../../data/treatment_recommendations.dart';
import '../../models/diagnosis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/crystal_panel.dart';

// Below this confidence, treat the image as "not one of the crops
// this model was trained on" rather than force-accepting a low-
// confidence guess. Mirrors model/pipeline.py's threshold exactly - keep
// both in sync. See that file's comment for the full reasoning.
const double kUnknownCropConfidenceThreshold = 0.6;

// The trained model runs on a local Python server (model/inference_server.py),
// not on-device - this avoids adding another native Android dependency
// (pytorch_lite/tflite/onnxruntime) on top of an already fragile
// NDK/build setup. Reach it via `adb reverse tcp:8000 tcp:8000` over
// the same USB cable used for `flutter run` - that maps this
// "localhost" address on the PHONE to the server running on your
// computer, no WiFi network config needed.
const String kInferenceServerUrl = 'http://localhost:8000/classify';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  // Bytes, not a dart:io File - File doesn't work on Flutter Web (no
  // real filesystem in a browser). Bytes is the one representation
  // that works identically on web, Android, and iOS, so the whole
  // capture pipeline (preview, verification, severity, upload) uses
  // Uint8List end to end rather than branching per-platform.
  Uint8List? _selectedImageBytes;
  bool _processing = false;
  String? _statusMessage;
  final ImagePicker _picker = ImagePicker();

  final _verificationService = ImageVerificationService();
  final _severityService = SeverityEstimationService();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _statusMessage = null;
      });
    }
  }

  /// Calls the real trained model, served locally by
  /// model/inference_server.py. Tries localhost (USB adb reverse) first,
  /// then falls back to the PC's Wi-Fi IP (10.12.103.0).
  Future<(String, double)> _classifyDisease(Uint8List bytes) async {
    final candidateUrls = [
      'http://10.179.243.22:8000/classify',
      'http://localhost:8000/classify',
      'http://10.12.103.0:8000/classify',
      'http://172.17.137.171:8000/classify',
    ];

    Object? lastError;

    for (final url in candidateUrls) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(url))
          ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'leaf.jpg'));

        final streamedResponse =
            await request.send().timeout(const Duration(seconds: 10));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return (
            data['predicted_class'] as String,
            (data['confidence'] as num).toDouble()
          );
        } else {
          lastError = Exception(
              'Server returned status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
        'Cannot reach ML Inference Server.\n\n'
        '• If phone is connected via USB: Run "adb reverse tcp:8000 tcp:8000" on PC.\n'
        '• If on Wi-Fi: Ensure phone & PC are on the same network.\n'
        '• Ensure "python model/inference_server.py" is running on PC.\n'
        'Details: $lastError');
  }

  Future<void> _submit() async {
    if (_selectedImageBytes == null) return;
    setState(() {
      _processing = true;
      _statusMessage = 'Verifying image...';
    });

    try {
      final service = context.read<SupabaseService>();
      final bytes = _selectedImageBytes!;

      // ---- Stage 1: Image Verification (on-device, before upload) ----
      final verification = await _verificationService.verify(bytes);

      if (!verification.isValid) {
        final rejectedDiagnosis = Diagnosis(
          imageUrl: '', // not uploaded - rejected before upload to save bandwidth
          isValidLeaf: false,
          rejectionReason: verification.rejectionReason,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/result', arguments: rejectedDiagnosis);
        return;
      }

      setState(() => _statusMessage = 'Uploading image...');
      final imageUrl = await service.uploadLeafImage(bytes);

      // ---- Stage 2: Disease Classification (real trained model) ----
      setState(() => _statusMessage = 'Classifying disease...');
      final (predictedDisease, confidence) = await _classifyDisease(bytes);

      // ---- Stage 2a: Unknown-crop check ----
      // A photo of something the model never saw during training
      // (a crop outside the trained classes, or an unrelated object)
      // should surface as "not supported", not a confident-looking
      // wrong diagnosis. Not persisted to history, same as a rejected
      // image - there's no real diagnosis to save.
      if (confidence < kUnknownCropConfidenceThreshold) {
        final unknownCropDiagnosis = Diagnosis(
          imageUrl: imageUrl,
          isValidLeaf: true,
          isUnknownCrop: true,
          confidence: confidence,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/result', arguments: unknownCropDiagnosis);
        return;
      }

      // ---- Stage 3: Severity Estimation (on-device) ----
      setState(() => _statusMessage = 'Estimating severity...');
      final severity = await _severityService.estimate(
        bytes,
        cropName: predictedDisease.split('___')[0],
      );

      // ---- Stage 4: Treatment Recommendation ----
      final treatment = getRecommendation(predictedDisease, severity.stage);

      final diagnosis = Diagnosis(
        imageUrl: imageUrl,
        isValidLeaf: true,
        predictedDisease: predictedDisease,
        confidence: confidence,
        severityStage: SeverityStageX.fromCode(severity.stage),
        severityPercent: severity.severityPercent,
        treatmentRecommendation: treatment.recommendation,
        preventionTips: treatment.prevention,
      );

      await service.saveDiagnosis(diagnosis);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/result', arguments: diagnosis);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: const GradientAppBar(title: 'Diagnose Leaf'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: CrystalPanel(
                padding: EdgeInsets.zero,
                radius: 24,
                accent: AppColors.canopy,
                child: SizedBox(
                  width: double.infinity,
                child: _selectedImageBytes == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.canopy.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.image_search,
                                  size: 48, color: AppColors.canopy.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No leaf photo yet',
                              style: TextStyle(
                                  color: AppColors.ink.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Take a photo or choose one below',
                              style: TextStyle(
                                  color: AppColors.ink.withValues(alpha: 0.35),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CaptureActionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppColors.canopy,
                    onTap: _processing ? null : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CaptureActionButton(
                    icon: Icons.photo_library,
                    label: 'Upload',
                    color: AppColors.rust,
                    onTap: _processing ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text(_statusMessage!,
                      style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6))),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: (_selectedImageBytes == null || _processing)
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.canopy, Color(0xFF3D6B42)]),
                  color: (_selectedImageBytes == null || _processing)
                      ? AppColors.darkSurfaceElevated
                      : null,
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed:
                      (_selectedImageBytes == null || _processing) ? null : _submit,
                  child: _processing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Analyze Leaf'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CaptureActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? AppColors.darkSurfaceElevated : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: disabled ? Colors.grey : color),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: disabled ? Colors.grey : color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
