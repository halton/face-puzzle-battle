import 'dart:async';
import 'package:camera/camera.dart';

/// Web implementation of blink detection.
/// On web, ML Kit is not available so we use a tap-based fallback
/// (user taps the screen instead of blinking).
class BlinkDetectionServiceWeb {
  CameraController? _cameraController;

  // Callbacks
  Function()? onBlink;
  Function(double leftEar, double rightEar)? onEarUpdate;

  /// Initialize camera for web (front camera, no image stream needed)
  Future<CameraController?> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      return _cameraController;
    } catch (e) {
      // Camera may not be available on web
      return null;
    }
  }

  /// On web, blink detection is replaced by tap detection
  void startDetection() {
    // No-op on web - use triggerBlink() from tap handler
  }

  void stopDetection() {
    // No-op on web
  }

  /// Manually trigger a "blink" (called from tap handler on web)
  void triggerBlink() {
    onBlink?.call();
  }

  void dispose() {
    _cameraController?.dispose();
  }
}
