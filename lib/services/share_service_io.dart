import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveImage(Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final subDir = Directory('${dir.path}/face_puzzle_results');
    if (!await subDir.exists()) {
      await subDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${subDir.path}/result_$timestamp.png');
    await file.writeAsBytes(bytes);
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> shareImage(Uint8List bytes, double score) async {
  try {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/face_puzzle_result_$timestamp.png');
    await file.writeAsBytes(bytes);

    final scoreText = score.toStringAsFixed(1);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '🎭 拼脸大作战！我的得分: $scoreText分！来挑战我吧！',
    );
  } catch (_) {}
}
