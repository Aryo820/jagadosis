import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth] for email/password authentication.
///
/// Centralises sign-up, sign-in, password reset and sign-out so the UI never
/// touches [FirebaseAuth] directly, and translates [FirebaseAuthException]s
/// into Indonesian, user-facing messages via [messageFromException].
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The currently signed-in user, or null when signed out.
  User? get currentUser => _auth.currentUser;

  /// Registers a new account and stores [name] as its display name.
  /// Throws [FirebaseAuthException] on failure (e.g. email already in use).
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name);
    await user.reload();
    return _auth.currentUser ?? user;
  }

  /// Signs in with [email] and [password].
  /// Throws [FirebaseAuthException] on failure (e.g. wrong password).
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  /// Sends a password-reset email to [email].
  /// Throws [FirebaseAuthException] on failure (e.g. user not found).
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Signs the current user out.
  Future<void> signOut() => _auth.signOut();

  /// Maps a [FirebaseAuthException] to an Indonesian, user-facing message.
  static String messageFromException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan masuk.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
