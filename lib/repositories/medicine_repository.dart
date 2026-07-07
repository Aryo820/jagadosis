import 'dart:developer';

import 'package:aplikasi/models/medicine_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository managing medicine data in Cloud Firestore, scoped to the
/// signed-in user at `users/{uid}/medicines/{id}`.
///
/// The public interface matches the previous SQLite-backed version so the UI
/// layers are unchanged. Firestore's offline persistence keeps reads working
/// without a connection; writes are applied to the local cache immediately and
/// synced when the device reconnects.
class MedicineRepository {
  MedicineRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// The current user's `medicines` sub-collection, or null when signed out.
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('medicines');
  }

  /// Adds a new medicine, keyed by its app-generated [MedicineModel.id].
  Future<void> addMedicine(MedicineModel medicine) async {
    final col = _col;
    if (col == null) return;
    await _commit(col.doc(medicine.id).set(medicine.toMap()));
  }

  /// Retrieves all of the current user's medicines. Served from the offline
  /// cache when there's no connection. Returns empty when signed out.
  Future<List<MedicineModel>> getAllMedicines() async {
    final col = _col;
    if (col == null) return [];
    final snapshot = await col.get();
    return snapshot.docs
        .map((doc) => MedicineModel.fromMap(doc.data()))
        .toList();
  }

  /// Updates an existing medicine (merge write, keyed by its id).
  Future<void> updateMedicine(MedicineModel medicine) async {
    final col = _col;
    if (col == null) return;
    await _commit(
      col.doc(medicine.id).set(medicine.toMap(), SetOptions(merge: true)),
    );
  }

  /// Deletes a medicine by its id.
  Future<void> deleteMedicine(String id) async {
    final col = _col;
    if (col == null) return;
    await _commit(col.doc(id).delete());
  }

  /// Awaits a write but never longer than a few seconds: with offline
  /// persistence the write Future only resolves once the server acknowledges,
  /// which never happens while offline. The local cache mutation is already
  /// applied synchronously, so timing out here lets the UI proceed and read
  /// its own write back from the cache; Firestore syncs the write on reconnect.
  Future<void> _commit(Future<void> write) {
    return write.timeout(
      const Duration(seconds: 3),
      // Expected while offline: the local cache mutation already applied, so the
      // UI can proceed and Firestore syncs on reconnect. Logged (not swallowed)
      // so a persistent stall is visible during debugging.
      onTimeout: () => log(
        'MedicineRepository: write not acknowledged within 3s (offline?); '
        'applied locally, will sync on reconnect',
      ),
    );
  }
}
