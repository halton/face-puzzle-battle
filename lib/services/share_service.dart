import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for saving and sharing game result images
class ShareService {
  /// Capture a widget as an image using RepaintBoundary key
  static Future<File?> captureWidget(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/face_puzzle_result_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Save result image to app documents (persistent storage)
  static Future<File?> saveToGallery(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final subDir = Directory('${dir.path}/face_puzzle_results');
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${subDir.path}/result_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Share the result image via system share sheet
  static Future<void> shareResult({
    required GlobalKey repaintKey,
    required double score,
  }) async {
    final file = await captureWidget(repaintKey);
    if (file == null) return;

    final scoreText = score.toStringAsFixed(1);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '🎭 拼脸大作战！我的得分: $scoreText分！来挑战我吧！',
    );
  }

  /// Get list of previously saved results
  static Future<List<File>> getSavedResults() async {
    final dir = await getApplicationDocumentsDirectory();
    final subDir = Directory('${dir.path}/face_puzzle_results');
    if (!await subDir.exists()) return [];

    final files = await subDir.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }
}
