import 'dart:async';
import 'dart:developer';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/user_profile_model.dart';
import 'package:aplikasi/repositories/user_profile_repository.dart';

/// Mengatur profil pengguna di dua tempat penyimpanannya: Cloud Firestore
/// (sumber kebenaran yang tahan lama dan lintas perangkat) dan SharedPreferences
/// (cache lokal yang dibaca UI secara sinkron dan saat offline).
///
/// Dengan menyatukan titik sambung ini di satu tempat, halaman/alur autentikasi
/// cukup memanggil satu metode yang jelas maksudnya, dan tidak perlu tahu bahwa
/// ada dua tempat penyimpanan.
class ProfileService {
  ProfileService({UserProfileRepository? repository})
    : _repo = repository ?? UserProfileRepository();

  final UserProfileRepository _repo;

  /// Mengisi dokumen Firestore awal tepat setelah pendaftaran (selagi akun baru
  /// masih terautentikasi). Pada tahap ini hanya nama/email yang diketahui;
  /// penulisan merge menyisakan ruang untuk detail medis yang ditambahkan nanti.
  ///
  /// Bila [consentVersion]/[termsVersion] diberikan, versi kebijakan privasi dan
  /// ketentuan yang disetujui beserta waktu persetujuannya ikut dicatat bersama
  /// profil, sehingga ada jejak audit yang tahan lama tentang apa yang disetujui
  /// pengguna saat mendaftar.
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

  /// Menarik profil dari server ke cache lokal setelah login agar sapaan, halaman
  /// profil, dan formulir Data Diri mencerminkan data yang dimasukkan di perangkat
  /// lain. Diam saja (tidak melakukan apa-apa) bila pengguna belum punya dokumen
  /// profil.
  Future<void> pullIntoCache() async {
    final profile = await _repo.fetch();
    if (profile == null) return;
    await _writeCache(profile);
  }

  /// Menyimpan perubahan profil. Menulis cache lokal terlebih dahulu agar UI
  /// langsung ter-update, lalu menyerahkan penulisan ke Firestore tanpa menunggu
  /// (await): dengan persistensi offline aktif, meng-await `set()` akan
  /// menggantung sampai perangkat terhubung kembali. Firestore mengantrekan
  /// penulisan secara lokal dan menyinkronkannya saat kembali online.
  Future<void> saveProfile(UserProfile profile) async {
    await _writeCache(profile);
    // Kirim-lalu-lupakan (fire-and-forget), tetapi tetap tampilkan kegagalannya:
    // error izin/kuota kalau tidak akan hilang diam-diam, meninggalkan cache dan
    // Firestore tidak sinkron tanpa jejak. Penulisan saat offline tetap
    // diantrekan dan diselesaikan nanti, jadi timeout di sini bukan sebuah
    // kegagalan — hanya error sungguhan yang sampai ke catchError.
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
