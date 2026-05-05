import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> saveImage(Uint8List bytes) async {
  try {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'face_puzzle_result_${DateTime.now().millisecondsSinceEpoch}.png')
      ..click();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> shareImage(Uint8List bytes, double score) async {
  // On web, just download the file
  await saveImage(bytes);
}
