import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class StorageService {
  static const _dataFile = 'projects.json';

  /// Base directory for app data (projects.json, photos).
  static Future<Directory> baseDir() async {
    final Directory base;
    if (Platform.isAndroid) {
      base = (await getExternalStorageDirectory())!;
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final dir = Directory('${base.path}/BookScanner');
    await dir.create(recursive: true);
    return dir;
  }

  /// Directory where exported PDFs are saved.
  /// On macOS: ~/Downloads/BookScanner — visible to the user.
  /// On Android: same as baseDir (external storage).
  static Future<Directory> exportDir() async {
    if (Platform.isMacOS) {
      final downloads = await getDownloadsDirectory();
      final dir = Directory('${downloads!.path}/BookScanner');
      await dir.create(recursive: true);
      return dir;
    }
    return baseDir();
  }

  static Future<File> _file() async {
    final dir = await baseDir();
    return File('${dir.path}/$_dataFile');
  }

  static Future<List<Project>> loadProjects() async {
    final file = await _file();
    if (!await file.exists()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      return list
          .map((j) => Project.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProjects(List<Project> projects) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  }
}
