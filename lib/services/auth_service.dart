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

  /// Registers a new account, stores [name] as its display name and sends a
  /// verification email to [email] so the address can be proven to belong to
  /// the user.
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
    // Fire off the verification email while the new account is still signed in
    // (sendEmailVerification requires an authenticated user).
    await user.sendEmailVerification();
    await user.reload();
    return _auth.currentUser ?? user;
  }

  /// Whether the signed-in user has confirmed their email address.
  /// False when signed out.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Re-sends the verification email to the current user.
  /// Throws [FirebaseAuthException] on failure (e.g. too many requests).
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Refreshes the current user from the server so [isEmailVerified] reflects a
  /// verification the user just completed in their browser.
  ///
  /// reload() only updates the client-side [User.emailVerified] flag. Firestore
  /// security rules, however, read `email_verified` from the ID *token*, which
  /// is cached (~1 hour) and is NOT refreshed by reload(). Without forcing a new
  /// token, a just-verified user still fails every verification-gated write
  /// (e.g. adding a medicine) with permission-denied even though the app thinks
  /// they're verified. getIdToken(true) mints a fresh token carrying the updated
  /// claim, so the rules and the app agree.
  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
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
