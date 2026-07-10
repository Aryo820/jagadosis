import 'dart:developer';

import 'package:aplikasi/models/medicine_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository yang mengelola data obat di Cloud Firestore, dibatasi per
/// pengguna yang sedang login pada `users/{uid}/medicines/{id}`.
///
/// Antarmuka publiknya sama dengan versi lama yang memakai SQLite, sehingga
/// lapisan UI tidak perlu diubah. Fitur offline Firestore membuat operasi baca
/// tetap jalan tanpa koneksi; operasi tulis langsung diterapkan ke cache lokal
/// dan disinkronkan saat perangkat kembali online.
class MedicineRepository {
  MedicineRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Sub-koleksi `medicines` milik pengguna saat ini, atau null jika belum login.
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('medicines');
  }

  /// Menambahkan obat baru, dengan kunci berupa [MedicineModel.id] yang dibuat aplikasi.
  Future<void> addMedicine(MedicineModel medicine) async {
    final col = _col;
    if (col == null) return;
    await _commit(col.doc(medicine.id).set(medicine.toMap()));
  }

  /// Mengambil semua obat milik pengguna saat ini. Dilayani dari cache offline
  /// saat tidak ada koneksi. Mengembalikan list kosong jika belum login.
  Future<List<MedicineModel>> getAllMedicines() async {
    final col = _col;
    if (col == null) return [];
    final snapshot = await col.get();
    return snapshot.docs
        .map((doc) => MedicineModel.fromMap(doc.data()))
        .toList();
  }

  /// Memperbarui obat yang sudah ada (tulis merge, dengan kunci berupa id-nya).
  Future<void> updateMedicine(MedicineModel medicine) async {
    final col = _col;
    if (col == null) return;
    await _commit(
      col.doc(medicine.id).set(medicine.toMap(), SetOptions(merge: true)),
    );
  }

  /// Menghapus obat berdasarkan id-nya.
  Future<void> deleteMedicine(String id) async {
    final col = _col;
    if (col == null) return;
    await _commit(col.doc(id).delete());
  }

  /// Menunggu operasi tulis, tapi tidak pernah lebih dari beberapa detik: dengan
  /// fitur offline, Future tulis baru selesai setelah server memberi konfirmasi,
  /// yang tidak akan terjadi saat offline. Perubahan pada cache lokal sudah
  /// diterapkan secara sinkron, jadi timeout di sini membuat UI bisa lanjut dan
  /// membaca kembali hasil tulisannya dari cache; Firestore akan menyinkronkan
  /// tulisan tersebut saat kembali online.
  Future<void> _commit(Future<void> write) {
    return write.timeout(
      const Duration(seconds: 3),
      // Wajar terjadi saat offline: perubahan cache lokal sudah diterapkan, jadi
      // UI bisa lanjut dan Firestore menyinkronkan saat kembali online. Tetap
      // dicatat (bukan diabaikan) agar kemacetan yang terus-menerus terlihat
      // saat debugging.
      onTimeout: () => log(
        'MedicineRepository: write not acknowledged within 3s (offline?); '
        'applied locally, will sync on reconnect',
      ),
    );
  }
}
