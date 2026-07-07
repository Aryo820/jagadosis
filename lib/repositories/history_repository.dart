import 'dart:developer';

import 'package:aplikasi/models/history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Repository managing consumption history in Cloud Firestore, scoped to the
/// signed-in user at `users/{uid}/history/{id}`.
///
/// `takenAt` is stored as an ISO-8601 string (via [HistoryModel.toMap]), which
/// sorts lexicographically in the same order as chronologically — so range
/// filters and ordering work directly on the string without extra indexes.
class HistoryRepository {
  HistoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');

  /// The current user's `history` sub-collection, or null when signed out.
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('history');
  }

  /// Adds a new consumption history entry, keyed by its id.
  Future<void> addHistory(HistoryModel history) async {
    final col = _col;
    if (col == null) return;
    await col
        .doc(history.id)
        .set(history.toMap())
        .timeout(
          const Duration(seconds: 3),
          // Expected while offline (mirrors MedicineRepository): applied to the
          // local cache, synced on reconnect. Logged so a real stall is visible.
          onTimeout: () => log(
            'HistoryRepository: write not acknowledged within 3s (offline?); '
            'applied locally, will sync on reconnect',
          ),
        );
  }

  /// Retrieves all history entries, newest first.
  Future<List<HistoryModel>> getAllHistories() async {
    final col = _col;
    if (col == null) return [];
    final snapshot = await col.orderBy('takenAt', descending: true).get();
    return _mapDocs(snapshot);
  }

  /// Retrieves history entries recorded on [date] (local calendar day).
  Future<List<HistoryModel>> getHistoriesByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _rangeQuery(start, end);
  }

  /// Retrieves history entries recorded within the given [month] of [year].
  Future<List<HistoryModel>> getHistoriesByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1); // month 13 rolls to next Jan
    return _rangeQuery(start, end);
  }

  /// Retrieves history entries recorded within the given [year].
  Future<List<HistoryModel>> getHistoriesByYear(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _rangeQuery(start, end);
  }

  /// Half-open range query [start, end) on the ISO `takenAt` string, newest
  /// first. The inequality and the ordering share the `takenAt` field, so
  /// Firestore serves it from a single-field index (no composite index needed).
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
