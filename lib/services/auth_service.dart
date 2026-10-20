import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  static Future<void> signOut() => _auth.signOut();

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Re-authenticates the current user with their password. Required by
  /// Firebase before sensitive operations like account deletion.
  static Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(cred);
  }

  /// Deletes the Firebase Auth account. Call AFTER the user's cloud data has
  /// been removed, since deleting the account revokes access to that data.
  static Future<void> deleteAccount() => _auth.currentUser!.delete();
}
