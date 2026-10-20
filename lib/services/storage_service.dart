import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class StorageService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('projects');

  // ── Firestore CRUD ─────────────────────────────────────────────────────────

  static Future<List<Project>> loadProjects() async {
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Project.fromJson(d.data())).toList();
  }

  /// Deletes every project document for the current user. Used by account
  /// deletion. Must run while the user is still authenticated.
  static Future<void> deleteAllData() async {
    final snap = await _col.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<void> saveProjects(List<Project> projects) async {
    final batch = _db.batch();
    final currentIds = projects.map((p) => p.id).toSet();

    // Remove deleted projects
    final existing = await _col.get();
    for (final doc in existing.docs) {
      if (!currentIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    // Upsert all current projects
    for (final p in projects) {
      batch.set(_col.doc(p.id), p.toJson());
    }

    await batch.commit();
  }

  // ── Local export directory (for PDFs) ─────────────────────────────────────

  /// Returns the directory where PDFs are exported.
  /// macOS uses Downloads, Android uses external app storage, and iOS uses the
  /// app's Documents directory so the PDF can be opened or shared.
  static Future<Directory> exportDir() async {
    if (Platform.isMacOS) {
      final downloads = await getDownloadsDirectory();
      final dir = Directory('${downloads!.path}/BookScanner');
      await dir.create(recursive: true);
      return dir;
    }
    final base = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final dir = Directory('${base!.path}/BookScanner');
    await dir.create(recursive: true);
    return dir;
  }
}
