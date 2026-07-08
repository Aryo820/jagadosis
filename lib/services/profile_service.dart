import 'dart:async';
import 'dart:developer';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/user_profile_model.dart';
import 'package:aplikasi/repositories/user_profile_repository.dart';

/// Orchestrates the user profile across its two stores: Cloud Firestore (the
/// durable, cross-device source of truth) and SharedPreferences (a local cache
/// the existing UI reads synchronously and offline).
///
/// Keeping this seam in one place means the pages/auth flows call a single,
/// intention-revealing method and never have to know both stores exist.
class ProfileService {
  ProfileService({UserProfileRepository? repository})
    : _repo = repository ?? UserProfileRepository();

  final UserProfileRepository _repo;

  /// Seeds the Firestore document right after registration (while the new
  /// account is still authenticated). Only name/email are known at this point;
  /// the merge write leaves room for medical details added later.
  ///
  /// When [consentVersion]/[termsVersion] are provided, the accepted
  /// privacy-policy and terms versions plus an acceptance timestamp are
  /// recorded alongside the profile, giving a durable audit trail of what the
  /// user agreed to at sign-up.
  Future<void> createInitial({
    required String name,
    required String email,
    String consentVersion = '',
    String termsVersion = '',
  }) {
    final hasConsent = consentVersion.isNotEmpty || termsVersion.isNotEmpty;
    return _repo.save(
      UserProfile(
        name: name,
        email: email,
        consentVersion: consentVersion,
        termsVersion: termsVersion,
        consentAcceptedAt: hasConsent
            ? DateTime.now().toUtc().toIso8601String()
            : '',
      ),
    );
  }

  /// Pulls the remote profile into the local cache after login so the greeting,
  /// profile page and Data Diri form reflect data entered on other devices.
  /// Silently does nothing when the user has no profile document yet.
  Future<void> pullIntoCache() async {
    final profile = await _repo.fetch();
    if (profile == null) return;
    await _writeCache(profile);
  }

  /// Persists profile edits. Writes the local cache first so the UI updates
  /// instantly, then hands the Firestore write off without awaiting it: with
  /// offline persistence enabled, awaiting `set()` would hang until the device
  /// reconnects. Firestore queues the write locally and syncs it on reconnect.
  Future<void> saveProfile(UserProfile profile) async {
    await _writeCache(profile);
    // Fire-and-forget, but surface failures: a permission/quota error would
    // otherwise vanish silently, leaving the cache and Firestore out of sync
    // with no trace. Offline writes still queue and resolve later, so a timeout
    // here isn't a failure — only real errors reach catchError.
    unawaited(
      _repo.save(profile).catchError(
        (e) => log('ProfileService: Firestore profile save failed: $e'),
      ),
    );
  }

  Future<void> _writeCache(UserProfile p) async {
    await PreferenceHandler.saveUser(p.name, p.email);
    await PreferenceHandler.saveBirthDate(p.birthDate);
    await PreferenceHandler.saveGender(p.gender);
    await PreferenceHandler.saveBloodType(p.bloodType);
    await PreferenceHandler.saveAllergies(p.allergies);
  }
}
