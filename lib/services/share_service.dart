import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Conditional imports for non-web
import 'share_service_io.dart' if (dart.library.html) 'share_service_web.dart'
    as platform;

/// Service for saving and sharing game result images
class ShareService {
  /// Capture a widget as an image using RepaintBoundary key
  static Future<Uint8List?> captureWidgetBytes(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Save result image
  static Future<bool> saveToGallery(GlobalKey repaintKey) async {
    final bytes = await captureWidgetBytes(repaintKey);
    if (bytes == null) return false;
    return platform.saveImage(bytes);
  }

  /// Share the result image via system share sheet
  static Future<void> shareResult({
    required GlobalKey repaintKey,
    required double score,
  }) async {
    final bytes = await captureWidgetBytes(repaintKey);
    if (bytes == null) return;
    await platform.shareImage(bytes, score);
  }
}
