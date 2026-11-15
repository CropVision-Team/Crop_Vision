import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Dart port of model/severity_estimation.py. Same union-of-healthy-and-
/// diseased-tissue leaf mask fix that was needed on the Python side -
/// see that file's docstring for why: diseased/necrotic pixels must be
/// counted as leaf area too, or severity gets silently deflated.
class SeverityResult {
  final double severityPercent;
  final String stage; // G0-G3
  final String label;

  SeverityResult({
    required this.severityPercent,
    required this.stage,
    required this.label,
  });
}

class SeverityEstimationService {
  // Same thresholds as the Python version - keep these two files in
  // sync if you retune against real leaf photos.
  static const Map<String, (double, double)> _defaultThresholds = {
    'G0': (0, 2),
    'G1': (2, 15),
    'G2': (15, 40),
    'G3': (40, 100),
  };

  // Per-crop overrides, mirroring
  // model/severity_estimation.py's CROP_SEVERITY_THRESHOLD_OVERRIDES -
  // empty until crop-specific cutoffs are validated against real
  // hand-checked photos per crop. Falls back to _defaultThresholds
  // for any crop not listed here.
  static const Map<String, Map<String, (double, double)>> _cropOverrides = {
    // Example once validated:
    // 'Tomato': {'G0': (0, 2), 'G1': (2, 12), 'G2': (12, 35), 'G3': (35, 100)},
  };

  static Map<String, (double, double)> _thresholdsFor(String? cropName) {
    if (cropName != null && _cropOverrides.containsKey(cropName)) {
      return _cropOverrides[cropName]!;
    }
    return _defaultThresholds;
  }

  static const Map<String, String> _labels = {
    'G0': 'Healthy',
    'G1': 'Mild Infection',
    'G2': 'Moderate Infection',
    'G3': 'Critical Infection',
  };

  /// See image_verification_service.dart's _rgbToHsv doc comment for
  /// why this normalizes by the pixel's own maxChannelValue instead of
  /// a hardcoded 255 - a real photo test showed this same bug here
  /// too (severity always computing as 0% regardless of actual
  /// disease content, for the same underlying reason).
  static (double h, double s, double v) _rgbToHsv(
      double r, double g, double b, double maxChannelValue) {
    final rf = r / maxChannelValue;
    final gf = g / maxChannelValue;
    final bf = b / maxChannelValue;
    final maxV = [rf, gf, bf].reduce(max);
    final minV = [rf, gf, bf].reduce(min);
    final delta = maxV - minV;

    double h;
    if (delta == 0) {
      h = 0;
    } else if (maxV == rf) {
      h = 60 * (((gf - bf) / delta) % 6);
    } else if (maxV == gf) {
      h = 60 * (((bf - rf) / delta) + 2);
    } else {
      h = 60 * (((rf - gf) / delta) + 4);
    }
    if (h < 0) h += 360;

    final s = maxV == 0 ? 0.0 : delta / maxV;
    final v = maxV;
    return (h, s, v);
  }

  /// Healthy green tissue: hue ~50-190 degrees (green through
  /// green-yellow), matching the Python green_lower/upper (25-95 in
  /// OpenCV's 0-179 scale -> ~50-190 degrees here).
  static bool _isHealthyPixel(double h, double s, double v) {
    return h >= 50 && h <= 190 && s >= 0.12 && v >= 0.08;
  }

  /// Diseased/necrotic tissue: brown/reddish, hue near 0 (with
  /// wrap-around near 360 for reddish tones camera white-balance can
  /// push that way). Matches Python's two-range disease mask.
  static bool _isDiseasedPixel(double h, double s, double v) {
    final inLowRange = h >= 0 && h <= 60 && s >= 0.12 && v >= 0.06 && v <= 0.8;
    final inWrapRange = h >= 340 && h <= 360 && s >= 0.12 && v >= 0.06 && v <= 0.8;
    return inLowRange || inWrapRange;
  }

  static String _percentToStage(double pct, Map<String, (double, double)> thresholds) {
    for (final entry in thresholds.entries) {
      final (low, high) = entry.value;
      if (pct >= low && pct < high) return entry.key;
    }
    return 'G3';
  }

  Future<SeverityResult> estimate(Uint8List bytes, {String? cropName}) async {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw ArgumentError('Could not decode image bytes');
    }

    final analysisImage =
        decoded.width > 512 ? img.copyResize(decoded, width: 512) : decoded;

    int leafPixels = 0;
    int diseasedPixels = 0;

    for (int y = 0; y < analysisImage.height; y++) {
      for (int x = 0; x < analysisImage.width; x++) {
        final px = analysisImage.getPixel(x, y);
        final (h, s, v) = _rgbToHsv(
            px.r.toDouble(), px.g.toDouble(), px.b.toDouble(), px.maxChannelValue.toDouble());

        final healthy = _isHealthyPixel(h, s, v);
        final diseased = _isDiseasedPixel(h, s, v);

        if (healthy || diseased) {
          leafPixels++;
          if (diseased) diseasedPixels++;
        }
      }
    }

    if (leafPixels == 0) {
      // Safety fallback - Image Verification should already have
      // caught a no-leaf image before this runs.
      return SeverityResult(severityPercent: 0.0, stage: 'G0', label: 'Healthy');
    }

    final pct = (diseasedPixels / leafPixels) * 100;
    final thresholds = _thresholdsFor(cropName);
    final stage = _percentToStage(pct, thresholds);

    return SeverityResult(
      severityPercent: double.parse(pct.toStringAsFixed(2)),
      stage: stage,
      label: _labels[stage]!,
    );
  }
}
