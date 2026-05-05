import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/painting.dart';

/// Service to process face images: remove features and create sprites
class ImageProcessingService {
  /// Remove a feature region from the face image (inpaint with surrounding skin)
  static img.Image removeFeature(img.Image source, Rect region) {
    final result = img.Image.from(source);
    final x = region.left.toInt().clamp(0, source.width - 1);
    final y = region.top.toInt().clamp(0, source.height - 1);
    final w = region.width.toInt().clamp(1, source.width - x);
    final h = region.height.toInt().clamp(1, source.height - y);

    // Simple inpainting: average surrounding pixels and fill
    // Collect border pixels for color sampling
    int totalR = 0, totalG = 0, totalB = 0, count = 0;

    // Sample top and bottom border
    for (int px = x; px < x + w; px++) {
      if (y > 0) {
        final p = result.getPixel(px, y - 1);
        totalR += p.r.toInt();
        totalG += p.g.toInt();
        totalB += p.b.toInt();
        count++;
      }
      if (y + h < source.height) {
        final p = result.getPixel(px, y + h);
        totalR += p.r.toInt();
        totalG += p.g.toInt();
        totalB += p.b.toInt();
        count++;
      }
    }
    // Sample left and right border
    for (int py = y; py < y + h; py++) {
      if (x > 0) {
        final p = result.getPixel(x - 1, py);
        totalR += p.r.toInt();
        totalG += p.g.toInt();
        totalB += p.b.toInt();
        count++;
      }
      if (x + w < source.width) {
        final p = result.getPixel(x + w, py);
        totalR += p.r.toInt();
        totalG += p.g.toInt();
        totalB += p.b.toInt();
        count++;
      }
    }

    if (count > 0) {
      final avgR = totalR ~/ count;
      final avgG = totalG ~/ count;
      final avgB = totalB ~/ count;

      // Fill with average + slight noise for natural look
      for (int py = y; py < y + h && py < source.height; py++) {
        for (int px = x; px < x + w && px < source.width; px++) {
          // Add slight gradient toward center for smoother blend
          final dx = (px - x) / w - 0.5;
          final dy = (py - y) / h - 0.5;
          final dist = (dx * dx + dy * dy) * 4;
          final blend = dist.clamp(0.0, 1.0);

          // Blend between border average and a slightly lighter skin tone
          final r = (avgR + (blend * 5).toInt()).clamp(0, 255);
          final g = (avgG + (blend * 3).toInt()).clamp(0, 255);
          final b = (avgB + (blend * 2).toInt()).clamp(0, 255);

          result.setPixelRgba(px, py, r, g, b, 255);
        }
      }
    }

    return result;
  }

  /// Crop a feature from source image
  static img.Image cropFeature(img.Image source, Rect region) {
    final x = region.left.toInt().clamp(0, source.width - 1);
    final y = region.top.toInt().clamp(0, source.height - 1);
    final w = region.width.toInt().clamp(1, source.width - x);
    final h = region.height.toInt().clamp(1, source.height - y);

    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }

  /// Convert img.Image to ui.Image for rendering
  static Future<ui.Image> convertToUiImage(img.Image image) async {
    final png = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Process full pipeline: extract features, create background, return sprites
  static Future<ProcessedFaceData> processFace(
    img.Image sourceImage,
    List<FeatureRegion> regions,
  ) async {
    var background = img.Image.from(sourceImage);

    final sprites = <ProcessedFeature>[];

    for (final region in regions) {
      // Crop feature sprite
      final cropped = cropFeature(sourceImage, region.rect);
      final sprite = await convertToUiImage(cropped);

      // Remove feature from background
      background = removeFeature(background, region.rect);

      sprites.add(ProcessedFeature(
        name: region.name,
        sprite: sprite,
        originalRect: region.rect,
      ));
    }

    final bgImage = await convertToUiImage(background);

    return ProcessedFaceData(
      background: bgImage,
      features: sprites,
      originalSize: Size(sourceImage.width.toDouble(), sourceImage.height.toDouble()),
    );
  }
}

/// Region of a feature on the face
class FeatureRegion {
  final String name;
  final Rect rect;
  FeatureRegion({required this.name, required this.rect});
}

/// A processed feature ready for game use
class ProcessedFeature {
  final String name;
  final ui.Image sprite;
  final Rect originalRect;
  ProcessedFeature({required this.name, required this.sprite, required this.originalRect});
}

/// Complete processed face data
class ProcessedFaceData {
  final ui.Image background;
  final List<ProcessedFeature> features;
  final Size originalSize;
  ProcessedFaceData({required this.background, required this.features, required this.originalSize});
}
