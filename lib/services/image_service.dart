import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageService {
  /// Longest edge (px) the saved image is downscaled to.
  static const int _maxEdge = 2048;

  /// JPEG quality (0-100) for the re-encoded image.
  static const int _quality = 85;

  /// Compresses [srcPath] (resize + JPEG re-encode) and returns the path to a
  /// new temp file. Falls back to the original path if anything goes wrong.
  static Future<String> compress(String srcPath) async {
    try {
      final bytes = await File(srcPath).readAsBytes();
      final out = await compute(_compressBytes, bytes);
      final dir = await getTemporaryDirectory();
      final dest = File(
          '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await dest.writeAsBytes(out);
      return dest.path;
    } catch (_) {
      return srcPath;
    }
  }
}

/// Runs in a background isolate via [compute].
Uint8List _compressBytes(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return input;

  img.Image im = img.bakeOrientation(decoded);

  final longest = im.width > im.height ? im.width : im.height;
  if (longest > ImageService._maxEdge) {
    if (im.width >= im.height) {
      im = img.copyResize(im, width: ImageService._maxEdge);
    } else {
      im = img.copyResize(im, height: ImageService._maxEdge);
    }
  }

  return img.encodeJpg(im, quality: ImageService._quality);
}
