import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'storage_service.dart';

class PdfExporter {
  /// Creates a PDF with one full-page photo per entry in [photoPaths].
  /// Each entry may be a local file path or a Firebase Storage download URL.
  static Future<File> export(List<String> photoPaths, String fileName) async {
    final doc = pw.Document();

    for (final path in photoPaths) {
      final bytes = await _loadBytes(path);
      if (bytes == null) continue;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        ),
      );
    }

    final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final dir = await StorageService.exportDir();
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<Uint8List?> _loadBytes(String path) async {
    try {
      if (path.startsWith('http')) {
        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) return response.bodyBytes;
        return null;
      }
      final file = File(path);
      if (await file.exists()) return await file.readAsBytes();
      return null;
    } catch (_) {
      return null;
    }
  }
}
