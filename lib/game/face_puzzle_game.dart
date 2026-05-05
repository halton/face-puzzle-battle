import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Represents a facial feature that falls from the top
class FacialFeatureComponent extends SpriteComponent with HasGameReference<FlameGame> {
  final String featureName;
  final Vector2 targetPosition;
  final double fallSpeed;
  bool isStopped = false;
  bool isActive = false;

  FacialFeatureComponent({
    required this.featureName,
    required this.targetPosition,
    this.fallSpeed = 150.0,
    required Vector2 size,
    required ui.Image image,
    required Rect sourceRect,
  }) : super(
          size: size,
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isActive && !isStopped) {
      position.y += fallSpeed * dt;

      // Auto-stop if reaches bottom
      if (position.y >= game.size.y - size.y / 2) {
        stop();
      }
    }
  }

  void start(double startX) {
    position = Vector2(startX, -size.y);
    isActive = true;
    isStopped = false;
  }

  void stop() {
    isStopped = true;
    isActive = false;
  }

  /// Calculate score based on distance from target position
  double getAccuracyScore() {
    if (!isStopped) return 0;
    final distance = position.distanceTo(targetPosition);
    final maxDistance = 200.0;
    return ((1.0 - (distance / maxDistance)).clamp(0.0, 1.0) * 100);
  }
}

/// Main game class for Face Puzzle
class FacePuzzleGame extends FlameGame with TapCallbacks {
  final List<FacialFeatureComponent> features = [];
  int currentFeatureIndex = 0;
  bool isGameActive = false;
  double totalScore = 0;

  // Callbacks
  Function(int index)? onFeatureChanged;
  Function(double score)? onGameComplete;
  Function()? onBlinkDetected;

  // Face background image
  ui.Image? faceBackground;
  Rect? faceRect;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Game will be initialized when face image is provided
  }

  /// Initialize game with extracted facial features
  void initializeWithFeatures(List<FeatureData> featureDataList) {
    features.clear();
    currentFeatureIndex = 0;
    totalScore = 0;
    isGameActive = false;

    // Features will be created from actual face detection data
    // Placeholder for now
  }

  /// Start the game - begins dropping first feature
  void startGame() {
    if (features.isEmpty) return;
    isGameActive = true;
    currentFeatureIndex = 0;
    _activateCurrentFeature();
  }

  /// Called when blink is detected - stops current feature
  void onBlink() {
    if (!isGameActive) return;
    if (currentFeatureIndex >= features.length) return;

    final current = features[currentFeatureIndex];
    if (current.isActive && !current.isStopped) {
      current.stop();
      _nextFeature();
    }
  }

  void _activateCurrentFeature() {
    if (currentFeatureIndex >= features.length) {
      _endGame();
      return;
    }

    final feature = features[currentFeatureIndex];
    feature.start(size.x / 2); // Start from center top
    onFeatureChanged?.call(currentFeatureIndex);
  }

  void _nextFeature() {
    currentFeatureIndex++;
    if (currentFeatureIndex >= features.length) {
      _endGame();
    } else {
      _activateCurrentFeature();
    }
  }

  void _endGame() {
    isGameActive = false;
    totalScore = 0;
    for (final feature in features) {
      totalScore += feature.getAccuracyScore();
    }
    totalScore = totalScore / features.length;
    onGameComplete?.call(totalScore);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Tap can also be used as alternative to blink (for testing)
    onBlink();
  }
}

/// Data class for facial feature extraction results
class FeatureData {
  final String name;
  final Rect boundingBox;
  final ui.Image? croppedImage;
  final Vector2 originalPosition;

  FeatureData({
    required this.name,
    required this.boundingBox,
    this.croppedImage,
    required this.originalPosition,
  });
}
