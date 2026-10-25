import 'dart:io';

/// Placeholder for on-device MobileViT inference.
///
/// NOT WIRED UP YET - intentionally. Reason: which Flutter package to
/// use for on-device PyTorch inference (pytorch_lite, tflite after
/// ONNX->TFLite conversion, onnxruntime, etc.) needs to be decided and
/// verified against pub.dev once you actually have a trained model to
/// export, since the package APIs vary and this environment has no
/// internet access to confirm any of them ahead of time. Guessing at
/// an exact API here would risk `flutter pub get`/`flutter analyze`
/// failures on your machine for a class nothing currently calls.
///
/// capture_screen.dart uses a mocked classifier
/// (`_classifyDiseaseMOCK`) instead of this class for now - see the
/// TODO comment there. Once train_mobilevit.py produces a checkpoint:
///   1. Export it (TorchScript via `torch.jit.script(model).save(...)`,
///      or convert to ONNX/TFLite - pick based on which Flutter
///      package you settle on).
///   2. Check that package's current pub.dev page for its real API.
///   3. Implement loadModel()/classify() below to match it.
///   4. Replace `_classifyDiseaseMOCK()` in capture_screen.dart with
///      a call to this class.
class InferenceService {
  bool get isReady => false;

  Future<void> loadModel() async {
    throw UnimplementedError(
      'Model inference not yet wired up - see class-level doc comment.',
    );
  }

  Future<(String, double)> classify(File imageFile) async {
    throw UnimplementedError(
      'Model inference not yet wired up - see class-level doc comment.',
    );
  }
}
