import 'dart:math';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service to detect blinks using Eye Aspect Ratio (EAR)
class BlinkDetectionService {
  final FaceDetector _faceDetector;
  CameraController? _cameraController;

  // EAR threshold for blink detection
  static const double _earThreshold = 0.21;
  static const int _consecutiveFrames = 2;

  int _blinkCounter = 0;
  bool _isEyeClosed = false;

  // Callbacks
  Function()? onBlink;
  Function(double leftEar, double rightEar)? onEarUpdate;

  BlinkDetectionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: true,
            enableLandmarks: true,
            performanceMode: FaceDetectorMode.fast,
            minFaceSize: 0.3,
          ),
        );

  /// Initialize camera for blink detection
  Future<CameraController?> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    // Use front camera
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
    return _cameraController;
  }

  /// Start continuous blink detection from camera stream
  void startDetection() {
    _cameraController?.startImageStream((image) {
      _processImage(image);
    });
  }

  /// Stop blink detection
  void stopDetection() {
    _cameraController?.stopImageStream();
  }

  /// Process a camera frame for blink detection
  Future<void> _processImage(CameraImage image) async {
    final inputImage = _convertCameraImage(image);
    if (inputImage == null) return;

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return;

    final face = faces.first;

    // Calculate EAR for both eyes
    final leftEar = _calculateEAR(face, FaceContourType.leftEye);
    final rightEar = _calculateEAR(face, FaceContourType.rightEye);

    onEarUpdate?.call(leftEar, rightEar);

    final avgEar = (leftEar + rightEar) / 2.0;

    if (avgEar < _earThreshold) {
      if (!_isEyeClosed) {
        _blinkCounter++;
        if (_blinkCounter >= _consecutiveFrames) {
          _isEyeClosed = true;
          onBlink?.call();
        }
      }
    } else {
      _isEyeClosed = false;
      _blinkCounter = 0;
    }
  }

  /// Calculate Eye Aspect Ratio from face contour points
  double _calculateEAR(Face face, FaceContourType eyeType) {
    final contour = face.contours[eyeType];
    if (contour == null || contour.points.length < 6) return 1.0;

    final points = contour.points;

    // EAR = (|p2-p6| + |p3-p5|) / (2 * |p1-p4|)
    // Using approximate point indices for eye contour
    final p1 = points[0];
    final p2 = points[1];
    final p3 = points[2];
    final p4 = points[3];
    final p5 = points[4];
    final p6 = points[5];

    final vertical1 = _distance(p2, p6);
    final vertical2 = _distance(p3, p5);
    final horizontal = _distance(p1, p4);

    if (horizontal == 0) return 1.0;
    return (vertical1 + vertical2) / (2.0 * horizontal);
  }

  double _distance(Point<int> a, Point<int> b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    // Platform-specific conversion
    final plane = image.planes.first;
    final bytes = plane.bytes;

    final imageSize = ui.Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // Assume front camera, portrait orientation
    const imageRotation = InputImageRotation.rotation270deg;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.close();
    _cameraController?.dispose();
  }
}
