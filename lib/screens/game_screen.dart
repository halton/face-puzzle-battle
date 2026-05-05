import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flame/game.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../game/face_puzzle_game_widget.dart';
import '../services/blink_detection_service.dart';
import '../services/face_extraction_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum GamePhase { capture, processing, playing, finished }

class _GameScreenState extends State<GameScreen> {
  GamePhase _phase = GamePhase.capture;
  final BlinkDetectionService _blinkService = BlinkDetectionService();
  final FaceExtractionService _extractionService = FaceExtractionService();
  FacePuzzleGameWidget? _game;

  CameraController? _cameraController;
  int _currentFeatureIndex = 0;
  String _currentFeatureName = '';
  double _totalScore = 0;
  final List<double> _featureScores = [];
  final List<String> _featureNames = [];
  bool _blinkIndicator = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameraController = await _blinkService.initializeCamera();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _blinkService.dispose();
    _extractionService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _phase == GamePhase.playing ? '拼脸中...' : '拼脸大作战',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_phase == GamePhase.playing)
            _BlinkIndicator(isBlinking: _blinkIndicator),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case GamePhase.capture:
        return _buildCaptureView();
      case GamePhase.processing:
        return _buildProcessingView();
      case GamePhase.playing:
        return _buildGameView();
      case GamePhase.finished:
        return _buildFinishedView();
    }
  }

  /// Camera capture / photo selection view
  Widget _buildCaptureView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _cameraController != null && _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white54),
                          SizedBox(height: 16),
                          Text('正在启动摄像头...',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Take photo button
              _CaptureButton(
                icon: Icons.camera_alt_rounded,
                label: '拍照',
                color: const Color(0xFFFF6B6B),
                onTap: _takePhoto,
              ),
              // Select from gallery
              _CaptureButton(
                icon: Icons.photo_library_rounded,
                label: '相册',
                color: const Color(0xFF4ECDC4),
                onTap: _selectFromGallery,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.deepPurple,
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            '正在识别面部特征...',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            '提取五官中 ✨',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// The actual Flame game view
  Widget _buildGameView() {
    return Column(
      children: [
        // Status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.cyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '当前: $_currentFeatureName — 眨眼停住！',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Text(
                '${_currentFeatureIndex + 1}/${_featureNames.length}',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Flame game
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _game != null
                  ? GameWidget(game: _game!)
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        // Feature progress bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _featureNames.length,
              (i) => Container(
                width: 40,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i < _currentFeatureIndex
                      ? Colors.green
                      : i == _currentFeatureIndex
                          ? Colors.amber
                          : Colors.white12,
                ),
              ),
            ),
          ),
        ),

        // Small camera preview for blink detection
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: 100,
            height: 130,
            margin: const EdgeInsets.only(right: 16, bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _blinkIndicator ? Colors.green : Colors.white24,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _cameraController != null && _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _totalScore >= 80 ? '🎉' : _totalScore >= 50 ? '😏' : '🤪',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            '得分: ${_totalScore.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/result'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('查看结果'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- Actions ---

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() => _phase = GamePhase.processing);

    try {
      final xFile = await _cameraController!.takePicture();
      await _processImage(File(xFile.path));
    } catch (e) {
      setState(() => _phase = GamePhase.capture);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  Future<void> _selectFromGallery() async {
    // TODO: Implement image picker
    // For now simulate with a placeholder
    setState(() => _phase = GamePhase.processing);

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual image processing
    _startGameWithDemo();
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final sourceImage = img.decodeImage(bytes);
      if (sourceImage == null) throw Exception('Failed to decode image');

      final inputImage = InputImage.fromFilePath(imageFile.path);
      final result = await _extractionService.extractFeatures(inputImage, sourceImage);

      if (result == null || result.features.isEmpty) {
        throw Exception('未检测到人脸');
      }

      // TODO: Convert extracted features to game sprites
      _startGameWithDemo();
    } catch (e) {
      setState(() => _phase = GamePhase.capture);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别失败: $e')),
        );
      }
    }
  }

  /// Start game with demo data (until real extraction is ready)
  void _startGameWithDemo() {
    _featureNames.clear();
    _featureNames.addAll(['左眉毛', '右眉毛', '左眼', '右眼', '鼻子', '嘴巴']);
    _featureScores.clear();
    _currentFeatureIndex = 0;
    _currentFeatureName = _featureNames[0];

    // Setup game engine
    _game = FacePuzzleGameWidget();
    _game!.onFeatureActivated = (index, name) {
      setState(() {
        _currentFeatureIndex = index;
        _currentFeatureName = name;
      });
    };
    _game!.onFeaturePlaced = (index, accuracy) {
      _featureScores.add(accuracy);
    };
    _game!.onAllPlaced = (score, scores) {
      setState(() {
        _totalScore = score;
        _phase = GamePhase.finished;
      });
    };

    // Start blink detection
    _blinkService.onBlink = () {
      _game?.placeCurrentFeature();
      setState(() => _blinkIndicator = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _blinkIndicator = false);
      });
    };
    _blinkService.startDetection();

    setState(() => _phase = GamePhase.playing);

    // Start dropping after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      _game?.startDrop();
    });
  }
}

/// Blink indicator widget
class _BlinkIndicator extends StatelessWidget {
  final bool isBlinking;
  const _BlinkIndicator({required this.isBlinking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBlinking ? Colors.green.withValues(alpha: 0.3) : Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlinking ? Colors.green : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_red_eye,
            size: 16,
            color: isBlinking ? Colors.green : Colors.white54,
          ),
          const SizedBox(width: 4),
          Text(
            isBlinking ? '眨眼!' : '👁️',
            style: TextStyle(
              fontSize: 12,
              color: isBlinking ? Colors.green : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Capture action button
class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
