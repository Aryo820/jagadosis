import 'package:firebase_auth/firebase_auth.dart';

/// Pembungkus ringan di atas [FirebaseAuth] untuk autentikasi email/kata sandi.
///
/// Memusatkan proses daftar, masuk, reset kata sandi, dan keluar agar UI tidak
/// pernah menyentuh [FirebaseAuth] secara langsung, serta menerjemahkan
/// [FirebaseAuthException] menjadi pesan berbahasa Indonesia yang ramah pengguna
/// lewat [messageFromException].
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Pengguna yang sedang login, atau null jika sedang tidak login.
  User? get currentUser => _auth.currentUser;

  /// Mendaftarkan akun baru, menyimpan [name] sebagai nama tampilan, dan
  /// mengirim email verifikasi ke [email] agar alamat tersebut bisa dibuktikan
  /// milik pengguna.
  /// Melempar [FirebaseAuthException] jika gagal (misal email sudah dipakai).
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
    // Kirim email verifikasi selagi akun baru masih dalam keadaan login
    // (sendEmailVerification membutuhkan pengguna yang sudah terautentikasi).
    await user.sendEmailVerification();
    await user.reload();
    return _auth.currentUser ?? user;
  }

  /// Apakah pengguna yang login sudah mengonfirmasi alamat emailnya.
  /// Bernilai false jika sedang tidak login.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Mengirim ulang email verifikasi ke pengguna saat ini.
  /// Melempar [FirebaseAuthException] jika gagal (misal terlalu banyak permintaan).
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Menyegarkan data pengguna saat ini dari server agar [isEmailVerified]
  /// mencerminkan verifikasi yang baru saja diselesaikan pengguna di browser.
  ///
  /// reload() hanya memperbarui flag [User.emailVerified] di sisi klien. Namun
  /// aturan keamanan Firestore membaca `email_verified` dari *token* ID, yang
  /// disimpan di cache (~1 jam) dan TIDAK ikut disegarkan oleh reload(). Tanpa
  /// memaksa token baru, pengguna yang baru terverifikasi tetap gagal pada setiap
  /// penulisan yang memerlukan verifikasi (misal menambah obat) dengan error
  /// permission-denied meski aplikasi mengira ia sudah terverifikasi.
  /// getIdToken(true) membuat token baru yang membawa klaim terbaru, sehingga
  /// aturan Firestore dan aplikasi menjadi selaras.
  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  /// Masuk (login) dengan [email] dan [password].
  /// Melempar [FirebaseAuthException] jika gagal (misal kata sandi salah).
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

  /// Mengirim email reset kata sandi ke [email].
  /// Melempar [FirebaseAuthException] jika gagal (misal pengguna tidak ditemukan).
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Mengeluarkan (logout) pengguna saat ini.
  Future<void> signOut() => _auth.signOut();

  /// Memetakan [FirebaseAuthException] menjadi pesan berbahasa Indonesia yang ramah pengguna.
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
