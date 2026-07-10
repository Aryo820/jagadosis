import 'package:aplikasi/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Membaca dan menulis dokumen profil milik user yang sedang login di Cloud Firestore.
///
/// Dokumennya berada di path `users/{uid}`, memakai uid dari Firebase Auth sebagai
/// kunci, sehingga tiap akun hanya bisa mengakses datanya sendiri (dijamin oleh
/// security rules). Semua operasi tidak melakukan apa-apa / mengembalikan null jika
/// tidak ada user yang login, jadi pemanggil tidak perlu mengecek sendiri kondisi belum-login.
class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _collection = 'users';

  /// Referensi dokumen profil milik user yang sedang login, atau null jika belum login.
  DocumentReference<Map<String, dynamic>>? get _docRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection(_collection).doc(uid);
  }

  /// Mengambil profil user yang sedang login, atau null jika belum login atau
  /// profilnya belum dibuat. Saat perangkat offline, data diambil dari cache Firestore.
  Future<UserProfile?> fetch() async {
    final ref = _docRef;
    if (ref == null) return null;

    final snapshot = await ref.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return UserProfile.fromMap(data);
  }

  /// Membuat atau memperbarui profil user yang sedang login. Memakai mode merge
  /// supaya pemanggil bisa menyimpan sebagian data profil saja (misal hanya nama/email
  /// saat registrasi) tanpa menimpa field lain yang diisi belakangan. Tidak melakukan
  /// apa-apa jika belum login.
  Future<void> save(UserProfile profile) async {
    final ref = _docRef;
    if (ref == null) return;

    await ref.set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
