import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Dart port of model/image_verification.py so the same quality/validity
/// checks run on-device before an image is uploaded (saves bandwidth
/// on obviously-bad photos and gives instant feedback to the farmer).
///
/// Ported logic, not a literal translation - OpenCV's Laplacian isn't
/// available here, so blur is estimated via a manual 3x3 Laplacian
/// convolution on the grayscale image, which measures the same thing
/// (edge/detail variance) the Python version does.
class VerificationResult {
  final bool isValid;
  final String? rejectionReason;
  final double? blurScore;
  final double? brightness;
  final double plantPixelRatio;

  VerificationResult({
    required this.isValid,
    this.rejectionReason,
    this.blurScore,
    this.brightness,
    this.plantPixelRatio = 0.0,
  });
}

class ImageVerificationService {
  static const int minResolution = 224;
  static const double blurThreshold = 100.0;
  static const double minBrightness = 40;
  static const double maxBrightness = 220;
  static const double minPlantPixelRatio = 0.15;

  /// Convert RGB to HSV. r/g/b are raw channel values in whatever
  /// scale the image package's Pixel object uses for THIS image
  /// (varies by pixel format), and maxChannelValue is that same
  /// pixel's own reported maximum - dividing by it, rather than a
  /// hardcoded 255, is what makes this correct regardless of the
  /// underlying format.
  ///
  /// BUG HISTORY: the original version divided by a hardcoded 255.0
  /// and read channels via `.toInt()`, assuming 0-255 int values. A
  /// real test against a photo that was 91.8%+ plant material (verified
  /// independently via OpenCV) came back with plant_pixel_ratio =
  /// EXACTLY 0.000 - every single pixel failed the check. That's the
  /// signature of channel values being silently truncated to 0 by
  /// `.toInt()` on values already in a smaller range than assumed
  /// (e.g. 0.0-1.0 doubles), not a threshold tuning problem. Normalizing
  /// by the pixel's own maxChannelValue fixes this regardless of which
  /// exact scale the package actually uses.
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

  /// Plant-colored pixel = green through yellow-brown hue range
  /// (roughly hue 30-220 in degrees), with enough saturation/value to
  /// not be background noise. Matches the intent of the Python
  /// _plant_pixel_ratio HSV range (hue 15-100 in OpenCV's 0-179 scale
  /// -> ~30-200 degrees here).
  static bool _isPlantPixel(double h, double s, double v) {
    return h >= 30 && h <= 220 && s >= 0.08 && v >= 0.08;
  }

  static double _blurScore(img.Image grayscale) {
    // Manual 3x3 Laplacian convolution, variance of the result ~=
    // OpenCV's cv2.Laplacian(...).var() used in the Python version.
    // Normalize each pixel to a 0-255 scale via maxChannelValue (see
    // _rgbToHsv doc comment for why this matters) so blurThreshold's
    // value of 100 stays meaningful regardless of the image's actual
    // internal pixel format.
    final kernel = [0, 1, 0, 1, -4, 1, 0, 1, 0];
    final w = grayscale.width, h = grayscale.height;
    final values = <double>[];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        double sum = 0;
        int k = 0;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final px = grayscale.getPixel(x + dx, y + dy);
            final normalized = (px.r / px.maxChannelValue) * 255.0;
            sum += normalized * kernel[k];
            k++;
          }
        }
        values.add(sum);
      }
    }

    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    return variance;
  }

  static double _brightness(img.Image grayscale) {
    double sum = 0;
    int count = 0;
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final px = grayscale.getPixel(x, y);
        sum += (px.r / px.maxChannelValue) * 255.0;
        count++;
      }
    }
    return count == 0 ? 0.0 : sum / count;
  }

  /// Downscale before pixel-looping for speed - phone photos can be
  /// 3000px+ wide, and we don't need full resolution to estimate blur/
  /// brightness/plant ratio reliably.
  static img.Image _prepareForAnalysis(img.Image original) {
    if (original.width > 512) {
      return img.copyResize(original, width: 512);
    }
    return original;
  }

  /// Takes raw image bytes rather than a dart:io File - File doesn't
  /// work on Flutter Web (no real filesystem in a browser), so bytes
  /// is the one representation that works identically on web, Android,
  /// and iOS. Get bytes from image_picker's XFile via .readAsBytes().
  Future<VerificationResult> verify(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return VerificationResult(
        isValid: false,
        rejectionReason: 'File could not be read as an image.',
      );
    }

    final originalWidth = decoded.width;
    final originalHeight = decoded.height;

    if (min(originalWidth, originalHeight) < minResolution) {
      return VerificationResult(
        isValid: false,
        rejectionReason:
            'Image resolution too low (${originalWidth}x$originalHeight). '
            'Please retake closer to the leaf.',
      );
    }

    final analysisImage = _prepareForAnalysis(decoded);
    // .clone() here is CRITICAL - img.grayscale() mutates its input
    // image in place rather than returning an independent copy. A
    // real test with a real leaf photo proved this: the "color" image
    // used later for plant-pixel detection came back completely
    // desaturated (a sample pixel read r=151, g=151, b=151 - literally
    // grayscale) because it was the SAME object this grayscale() call
    // had already converted. Without cloning first, every downstream
    // color check silently operates on grayscale data and reports
    // zero plant pixels regardless of what's actually in the photo.
    final grayscale = img.grayscale(analysisImage.clone());

    // Brightness checked BEFORE blur - see the note in the Python
    // version's history: a dark image naturally has low contrast,
    // which depresses the blur score and causes false "too blurry"
    // rejections for what's really a lighting problem.
    final brightness = _brightness(grayscale);
    if (brightness < minBrightness) {
      return VerificationResult(
        isValid: false,
        rejectionReason: 'Image is too dark. Please retake in better lighting.',
        brightness: brightness,
      );
    }
    if (brightness > maxBrightness) {
      return VerificationResult(
        isValid: false,
        rejectionReason: 'Image is overexposed. Please avoid direct glare/flash.',
        brightness: brightness,
      );
    }

    final blur = _blurScore(grayscale);
    if (blur < blurThreshold) {
      return VerificationResult(
        isValid: false,
        rejectionReason:
            'Image is too blurry. Please hold the camera steady and refocus.',
        blurScore: blur,
        brightness: brightness,
      );
    }

    // Validity check: plant pixel ratio
    int plantPixels = 0;
    int totalPixels = 0;
    for (int y = 0; y < analysisImage.height; y++) {
      for (int x = 0; x < analysisImage.width; x++) {
        final px = analysisImage.getPixel(x, y);
        final (h, s, v) = _rgbToHsv(
            px.r.toDouble(), px.g.toDouble(), px.b.toDouble(), px.maxChannelValue.toDouble());
        if (_isPlantPixel(h, s, v)) plantPixels++;
        totalPixels++;
      }
    }
    final ratio = totalPixels == 0 ? 0.0 : plantPixels / totalPixels;

    if (ratio < minPlantPixelRatio) {
      return VerificationResult(
        isValid: false,
        rejectionReason:
            'No crop leaf detected in this image. Please photograph a leaf directly.',
        blurScore: blur,
        brightness: brightness,
        plantPixelRatio: ratio,
      );
    }

    return VerificationResult(
      isValid: true,
      blurScore: blur,
      brightness: brightness,
      plantPixelRatio: ratio,
    );
  }
}
