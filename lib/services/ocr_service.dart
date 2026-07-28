import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OcrService {
  /// On-device OCR is available on Android and iOS via ML Kit.
  /// (macOS has no ML Kit support; ML Kit also does not run on Apple-Silicon
  /// iOS simulators, but works on real iOS devices.)
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Recognizes text in a local image file. Uses the Chinese model, which also
  /// handles Latin script, matching the app's mixed Chinese/English content.
  static Future<String> recognizeFile(String localPath) async {
    final recognizer =
        TextRecognizer(script: TextRecognitionScript.chinese);
    try {
      final input = InputImage.fromFilePath(localPath);
      final result = await recognizer.processImage(input);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  /// Recognizes text in a remote image: downloads it to a temp file first,
  /// then runs on-device OCR.
  static Future<String> recognizeUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Could not download image (HTTP ${response.statusCode})');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    try {
      return await recognizeFile(file.path);
    } finally {
      try { await file.delete(); } catch (_) {}
    }
  }
}
