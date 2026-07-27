import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageService {
  /// Shortest edge (px) the saved image is scaled down toward.
  static const int _minEdge = 2000;

  /// JPEG quality (0-100) for the re-encoded image.
  static const int _quality = 85;

  /// Compresses [srcPath] and returns the path to a new temp file. Falls back
  /// to the original path if compression fails for any reason.
  ///
  /// On mobile this uses native compression (memory-safe for very high
  /// resolution camera images). On desktop it uses the pure-Dart `image`
  /// package, since flutter_image_compress has no macOS support.
  static Future<String> compress(String srcPath) async {
    try {
      final dir = await getTemporaryDirectory();
      final dest =
          '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (Platform.isAndroid || Platform.isIOS) {
        final result = await FlutterImageCompress.compressAndGetFile(
          srcPath,
          dest,
          minWidth: _minEdge,
          minHeight: _minEdge,
          quality: _quality,
          keepExif: false,
        );
        return result?.path ?? srcPath;
      }

      // Desktop fallback (macOS): pure-Dart resize on a background isolate.
      final bytes = await File(srcPath).readAsBytes();
      final out = await compute(_compressBytes, bytes);
      await File(dest).writeAsBytes(out);
      return dest;
    } catch (_) {
      return srcPath;
    }
  }
}

/// Desktop-only pure-Dart compression, runs in a background isolate.
Uint8List _compressBytes(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return input;

  img.Image im = img.bakeOrientation(decoded);

  const maxEdge = 2048;
  final longest = im.width > im.height ? im.width : im.height;
  if (longest > maxEdge) {
    if (im.width >= im.height) {
      im = img.copyResize(im, width: maxEdge);
    } else {
      im = img.copyResize(im, height: maxEdge);
    }
  }
  return img.encodeJpg(im, quality: 85);
}
