import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// The actual Flame game widget that renders the falling features
class FacePuzzleGameWidget extends FlameGame {
  /// Background face image (with features removed / blurred)
  ui.Image? faceBackgroundImage;

  /// Original face dimensions
  Size faceSize = Size.zero;

  /// All feature sprites to drop
  final List<DroppingFeature> _features = [];

  /// Currently active (falling) feature index
  int _activeIndex = -1;

  /// Game state
  GameState state = GameState.ready;

  /// Callbacks
  Function(int index, String name)? onFeatureActivated;
  Function(int index, double accuracy)? onFeaturePlaced;
  Function(double totalScore, List<double> scores)? onAllPlaced;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  /// Setup game with face background and feature sprites
  void setupGame({
    required ui.Image background,
    required List<FeatureSprite> featureSprites,
  }) {
    faceBackgroundImage = background;
    faceSize = Size(background.width.toDouble(), background.height.toDouble());

    // Clear previous
    _features.forEach((f) => f.removeFromParent());
    _features.clear();
    _activeIndex = -1;
    state = GameState.ready;

    // Add background as component
    add(FaceBackgroundComponent(background));

    // Create dropping features (shuffled order)
    final shuffled = List<FeatureSprite>.from(featureSprites)..shuffle(Random());

    for (final fs in shuffled) {
      final dropping = DroppingFeature(
        featureName: fs.name,
        sprite: fs.image,
        targetPosition: fs.targetPosition,
        featureSize: fs.size,
        fallSpeed: fs.fallSpeed,
      );
      _features.add(dropping);
      add(dropping);
    }
  }

  /// Start the game - activate first feature
  void startDrop() {
    if (_features.isEmpty) return;
    state = GameState.playing;
    _activeIndex = 0;
    _activateCurrent();
  }

  /// Called on blink or tap - place current feature
  void placeCurrentFeature() {
    if (state != GameState.playing) return;
    if (_activeIndex < 0 || _activeIndex >= _features.length) return;

    final current = _features[_activeIndex];
    if (!current.isDropping) return;

    current.place();
    final accuracy = current.calculateAccuracy();
    onFeaturePlaced?.call(_activeIndex, accuracy);

    // Next feature
    _activeIndex++;
    if (_activeIndex >= _features.length) {
      _finishGame();
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        _activateCurrent();
      });
    }
  }

  void _activateCurrent() {
    if (_activeIndex >= _features.length) return;
    final current = _features[_activeIndex];
    current.startDropping(size.x);
    onFeatureActivated?.call(_activeIndex, current.featureName);
  }

  void _finishGame() {
    state = GameState.finished;
    final scores = _features.map((f) => f.calculateAccuracy()).toList();
    final total = scores.reduce((a, b) => a + b) / scores.length;
    onAllPlaced?.call(total, scores);
  }

  /// Reset game for replay
  void reset() {
    _features.forEach((f) => f.removeFromParent());
    _features.clear();
    _activeIndex = -1;
    state = GameState.ready;
  }
}

/// Game states
enum GameState { ready, playing, finished }

/// Background face component (with features blanked out)
class FaceBackgroundComponent extends Component with HasGameReference<FlameGame> {
  final ui.Image image;

  FaceBackgroundComponent(this.image);

  @override
  void render(Canvas canvas) {
    // Center the face on screen
    final gameSize = game.size;
    final scale = min(
      gameSize.x * 0.8 / image.width,
      gameSize.y * 0.7 / image.height,
    );

    final drawWidth = image.width * scale;
    final drawHeight = image.height * scale;
    final offsetX = (gameSize.x - drawWidth) / 2;
    final offsetY = (gameSize.y - drawHeight) / 2 + 20;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight),
      Paint(),
    );
  }
}

/// A single dropping feature
class DroppingFeature extends PositionComponent with HasGameReference<FlameGame> {
  final String featureName;
  final ui.Image sprite;
  final Vector2 targetPosition; // Where it should land (in game coordinates)
  final Vector2 featureSize;
  final double fallSpeed;

  bool isDropping = false;
  bool isPlaced = false;
  double _elapsedSinceStart = 0;

  // Horizontal wobble
  double _wobblePhase = 0;
  final double _wobbleAmplitude = 15.0;
  final double _wobbleSpeed = 3.0;

  DroppingFeature({
    required this.featureName,
    required this.sprite,
    required this.targetPosition,
    required this.featureSize,
    this.fallSpeed = 150.0,
  }) : super(
          size: featureSize,
          anchor: Anchor.center,
        );

  @override
  void onMount() {
    super.onMount();
    // Start hidden above screen
    position = Vector2(-100, -100);
    _wobblePhase = Random().nextDouble() * pi * 2;
  }

  void startDropping(double screenWidth) {
    // Start from random X near center, above screen
    final startX = screenWidth / 2 + (Random().nextDouble() - 0.5) * screenWidth * 0.3;
    position = Vector2(startX, -featureSize.y);
    isDropping = true;
    isPlaced = false;
    _elapsedSinceStart = 0;
  }

  void place() {
    isDropping = false;
    isPlaced = true;
  }

  double calculateAccuracy() {
    if (!isPlaced) return 0;
    final dist = position.distanceTo(targetPosition);
    // Max distance for 0 score
    const maxDist = 200.0;
    return ((1.0 - dist / maxDist).clamp(0.0, 1.0) * 100);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isDropping) return;

    _elapsedSinceStart += dt;

    // Fall down
    position.y += fallSpeed * dt;

    // Gentle horizontal wobble
    _wobblePhase += _wobbleSpeed * dt;
    position.x += sin(_wobblePhase) * _wobbleAmplitude * dt;

    // Auto-place if hits bottom
    if (position.y >= game.size.y - featureSize.y) {
      place();
    }
  }

  @override
  void render(Canvas canvas) {
    if (position.x < -50 && position.y < -50) return; // Hidden

    final paint = Paint();
    if (isDropping) {
      // Slight glow effect while dropping
      paint.color = Colors.white;
    }

    canvas.drawImageRect(
      sprite,
      Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
      Rect.fromLTWH(0, 0, featureSize.x, featureSize.y),
      paint,
    );

    // Draw target hint (semi-transparent) if not placed
    if (isDropping) {
      final hintPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Draw target position hint
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            targetPosition.x - position.x + featureSize.x / 2,
            targetPosition.y - position.y + featureSize.y / 2,
          ),
          width: featureSize.x,
          height: featureSize.y,
        ),
        hintPaint,
      );
    }
  }
}

/// Data for a feature sprite
class FeatureSprite {
  final String name;
  final ui.Image image;
  final Vector2 targetPosition;
  final Vector2 size;
  final double fallSpeed;

  FeatureSprite({
    required this.name,
    required this.image,
    required this.targetPosition,
    required this.size,
    this.fallSpeed = 150.0,
  });
}
