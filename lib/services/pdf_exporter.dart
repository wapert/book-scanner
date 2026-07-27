import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'storage_service.dart';

class PdfExporter {
  /// Creates a PDF with one full-page photo per entry in [photoPaths].
  static Future<File> export(List<String> photoPaths, String fileName) async {
    final doc = pw.Document();

    for (final path in photoPaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      final bytes = await file.readAsBytes();
      final image = pw.MemoryImage(bytes);

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.contain),
      ));
    }

    final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final dir = await StorageService.exportDir();
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
