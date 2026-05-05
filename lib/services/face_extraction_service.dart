
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../game/face_puzzle_game.dart';
import 'package:flame/components.dart';

/// Service to detect faces and extract facial features
class FaceExtractionService {
  final FaceDetector _faceDetector;

  FaceExtractionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: true,
            enableLandmarks: true,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  /// Detect face and extract features from an image
  Future<FaceExtractionResult?> extractFeatures(InputImage inputImage, img.Image sourceImage) async {
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    final face = faces.first;
    final boundingBox = face.boundingBox;

    // Extract individual features based on landmarks
    final features = <FeatureData>[];

    // Left eyebrow
    final leftEyebrow = _extractContourRegion(
      face, FaceContourType.leftEyebrowTop, FaceContourType.leftEyebrowBottom,
      sourceImage, '左眉毛',
    );
    if (leftEyebrow != null) features.add(leftEyebrow);

    // Right eyebrow
    final rightEyebrow = _extractContourRegion(
      face, FaceContourType.rightEyebrowTop, FaceContourType.rightEyebrowBottom,
      sourceImage, '右眉毛',
    );
    if (rightEyebrow != null) features.add(rightEyebrow);

    // Left eye
    final leftEye = _extractContourFeature(
      face, FaceContourType.leftEye, sourceImage, '左眼',
    );
    if (leftEye != null) features.add(leftEye);

    // Right eye
    final rightEye = _extractContourFeature(
      face, FaceContourType.rightEye, sourceImage, '右眼',
    );
    if (rightEye != null) features.add(rightEye);

    // Nose
    final noseBridge = face.contours[FaceContourType.noseBridge];
    final noseBottom = face.contours[FaceContourType.noseBottom];
    if (noseBridge != null && noseBottom != null) {
      final allPoints = [...noseBridge.points, ...noseBottom.points];
      final noseFeature = _extractFromPoints(allPoints, sourceImage, '鼻子');
      if (noseFeature != null) features.add(noseFeature);
    }

    // Mouth
    final upperLip = face.contours[FaceContourType.upperLipTop];
    final lowerLip = face.contours[FaceContourType.lowerLipBottom];
    if (upperLip != null && lowerLip != null) {
      final allPoints = [...upperLip.points, ...lowerLip.points];
      final mouthFeature = _extractFromPoints(allPoints, sourceImage, '嘴巴');
      if (mouthFeature != null) features.add(mouthFeature);
    }

    return FaceExtractionResult(
      faceRect: boundingBox,
      features: features,
      faceImage: sourceImage,
    );
  }

  FeatureData? _extractContourRegion(
    Face face,
    FaceContourType topType,
    FaceContourType bottomType,
    img.Image sourceImage,
    String name,
  ) {
    final top = face.contours[topType];
    final bottom = face.contours[bottomType];
    if (top == null || bottom == null) return null;

    final allPoints = [...top.points, ...bottom.points];
    return _extractFromPoints(allPoints, sourceImage, name);
  }

  FeatureData? _extractContourFeature(
    Face face,
    FaceContourType type,
    img.Image sourceImage,
    String name,
  ) {
    final contour = face.contours[type];
    if (contour == null) return null;
    return _extractFromPoints(contour.points, sourceImage, name);
  }

  FeatureData? _extractFromPoints(
    List<Point<int>> points,
    img.Image sourceImage,
    String name,
  ) {
    if (points.isEmpty) return null;

    // Calculate bounding box with padding
    int minX = points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    int maxX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    int minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    int maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    // Add 10% padding
    final padX = ((maxX - minX) * 0.1).toInt();
    final padY = ((maxY - minY) * 0.1).toInt();
    minX = (minX - padX).clamp(0, sourceImage.width - 1);
    maxX = (maxX + padX).clamp(0, sourceImage.width - 1);
    minY = (minY - padY).clamp(0, sourceImage.height - 1);
    maxY = (maxY + padY).clamp(0, sourceImage.height - 1);

    final rect = Rect.fromLTRB(
      minX.toDouble(), minY.toDouble(),
      maxX.toDouble(), maxY.toDouble(),
    );

    final centerX = (minX + maxX) / 2.0;
    final centerY = (minY + maxY) / 2.0;

    return FeatureData(
      name: name,
      boundingBox: rect,
      originalPosition: Vector2(centerX, centerY),
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}

/// Result of face extraction
class FaceExtractionResult {
  final Rect faceRect;
  final List<FeatureData> features;
  final img.Image faceImage;

  FaceExtractionResult({
    required this.faceRect,
    required this.features,
    required this.faceImage,
  });
}
