import 'dart:developer';

import 'package:aplikasi/models/history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Repository yang mengelola riwayat konsumsi obat di Cloud Firestore, khusus
/// milik user yang sedang login, di path `users/{uid}/history/{id}`.
///
/// `takenAt` disimpan sebagai teks berformat ISO-8601 (lewat [HistoryModel.toMap]).
/// Urutan teks ISO-8601 secara alfabet sama dengan urutan waktunya — jadi filter
/// rentang tanggal dan pengurutan bisa langsung memakai teks itu tanpa index tambahan.
class HistoryRepository {
  HistoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');

  /// Sub-koleksi `history` milik user yang sedang login, atau null jika belum login.
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('history');
  }

  /// Menambahkan satu entri riwayat konsumsi baru, disimpan dengan id-nya.
  Future<void> addHistory(HistoryModel history) async {
    final col = _col;
    if (col == null) return;
    await col
        .doc(history.id)
        .set(history.toMap())
        .timeout(
          const Duration(seconds: 3),
          // Wajar terjadi saat offline (sama seperti MedicineRepository): data
          // ditulis ke cache lokal dulu, lalu disinkronkan saat online kembali.
          // Dicatat di log supaya kalau ada masalah nyata (bukan sekadar offline) tetap terlihat.
          onTimeout: () => log(
            'HistoryRepository: write not acknowledged within 3s (offline?); '
            'applied locally, will sync on reconnect',
          ),
        );
  }

  /// Mengambil semua entri riwayat, diurutkan dari yang terbaru.
  Future<List<HistoryModel>> getAllHistories() async {
    final col = _col;
    if (col == null) return [];
    final snapshot = await col.orderBy('takenAt', descending: true).get();
    return _mapDocs(snapshot);
  }

  /// Mengambil entri riwayat yang tercatat pada tanggal [date] (hari kalender lokal).
  Future<List<HistoryModel>> getHistoriesByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _rangeQuery(start, end);
  }

  /// Mengambil entri riwayat yang tercatat dalam bulan [month] pada tahun [year].
  Future<List<HistoryModel>> getHistoriesByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1); // bulan ke-13 otomatis jadi Januari tahun berikutnya
    return _rangeQuery(start, end);
  }

  /// Mengambil entri riwayat yang tercatat dalam tahun [year].
  Future<List<HistoryModel>> getHistoriesByYear(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _rangeQuery(start, end);
  }

  /// Query rentang setengah-terbuka [start, end) pada teks ISO `takenAt`, diurutkan
  /// dari yang terbaru. Karena syarat rentang dan pengurutan sama-sama memakai field
  /// `takenAt`, Firestore cukup memakai index satu field (tidak perlu composite index).
  Future<List<HistoryModel>> _rangeQuery(DateTime start, DateTime end) async {
    final col = _col;
    if (col == null) return [];
    final snapshot = await col
        .where('takenAt', isGreaterThanOrEqualTo: _dayFormat.format(start))
        .where('takenAt', isLessThan: _dayFormat.format(end))
        .orderBy('takenAt', descending: true)
        .get();
    return _mapDocs(snapshot);
  }

  List<HistoryModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => HistoryModel.fromMap(doc.data()))
        .toList();
  }
}
