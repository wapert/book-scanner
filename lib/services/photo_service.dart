import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PhotoService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Uploads [localPath] to Firebase Storage and returns the download URL.
  static Future<String> uploadPhoto(
    String localPath,
    String bookId, {
    void Function(double progress)? onProgress,
  }) async {
    final fileName = 'page_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('users/$_uid/books/$bookId/$fileName');

    final task = ref.putFile(File(localPath));

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    await task;
    return await ref.getDownloadURL();
  }

  /// Deletes a photo from Firebase Storage by its download URL.
  static Future<void> deletePhoto(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {}
  }

  /// Deletes ALL of the current user's stored files. Used by account deletion.
  static Future<void> deleteAllUserFiles() async {
    await _deleteRecursive(_storage.ref('users/$_uid'));
  }

  static Future<void> _deleteRecursive(Reference ref) async {
    final result = await ref.listAll();
    for (final item in result.items) {
      try { await item.delete(); } catch (_) {}
    }
    for (final prefix in result.prefixes) {
      await _deleteRecursive(prefix);
    }
  }
}
