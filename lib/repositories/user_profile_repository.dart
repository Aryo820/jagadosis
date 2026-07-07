import 'package:aplikasi/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reads and writes the signed-in user's profile document in Cloud Firestore.
///
/// The document lives at `users/{uid}`, keyed by the Firebase Auth uid so each
/// account only ever touches its own data (enforced by security rules). All
/// operations no-op / return null when there is no authenticated user, so
/// callers don't have to guard against the signed-out case themselves.
class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _collection = 'users';

  /// The current user's profile document reference, or null when signed out.
  DocumentReference<Map<String, dynamic>>? get _docRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection(_collection).doc(uid);
  }

  /// Fetches the current user's profile, or null if signed out or not yet
  /// created. Firestore's offline cache serves this when the device is offline.
  Future<UserProfile?> fetch() async {
    final ref = _docRef;
    if (ref == null) return null;

    final snapshot = await ref.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return UserProfile.fromMap(data);
  }

  /// Creates or updates the current user's profile. Uses merge so callers can
  /// save a partial profile (e.g. just name/email at registration) without
  /// clobbering fields filled in later. No-op when signed out.
  Future<void> save(UserProfile profile) async {
    final ref = _docRef;
    if (ref == null) return;

    await ref.set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
