import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyUserName = "userName";
  static const _keyUserEmail = "userEmail";
  static const _keyProfilePhoto = "profilePhoto";

  // Key untuk Data Diri
  static const _keyUserBirthDate = "userBirthDate";
  static const _keyUserGender = "userGender";
  static const _keyUserBloodType = "userBloodType";
  static const _keyUserAllergies = "userAllergies";

  // Key untuk Pengaturan Notifikasi
  static const _keyNotificationGlobal = "notificationGlobal";
  static const _keyNotificationSound = "notificationSound";
  static const _keyNotificationVibration = "notificationVibration";
  static const _keyNotificationSnooze = "notificationSnooze";
  // Nada dering alarm: [_keyAlarmSound] menyimpan nilai yang dikirim ke plugin
  // alarm (path bawaan `assets/...` atau path relatif terhadap folder Documents
  // aplikasi `alarm_sounds/...`), sedangkan [_keyAlarmSoundName] adalah label
  // yang ditampilkan di UI.
  static const _keyAlarmSound = "alarmSound";
  static const _keyAlarmSoundName = "alarmSoundName";

  /// Nada dering bawaan, dipakai saat pengguna belum memilih suara lain.
  static const String defaultAlarmSound = "assets/audio/ggmu.mp3";
  static const String defaultAlarmSoundName = "Bawaan (GGMU)";

  // Key untuk Kontak Darurat
  static const _keyEmergencyContacts = "emergencyContacts";

  static Future<void> setLogin(bool isLogin) async {
    await _prefs.setBool(_keyIsLogin, isLogin);
  }

  static bool get isLogin {
    return _prefs.getBool(_keyIsLogin) ?? false;
  }

  static Future<void> saveUser(String name, String email) async {
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setBool(_keyIsLogin, true);
  }

  static String get userName {
    return _prefs.getString(_keyUserName) ?? '';
  }

  static String get userEmail {
    return _prefs.getString(_keyUserEmail) ?? '';
  }

  /// Menyimpan path absolut file foto profil pengguna.
  static Future<void> saveProfilePhoto(String path) async {
    await _prefs.setString(_keyProfilePhoto, path);
  }

  /// Mengembalikan path foto profil yang tersimpan, atau null jika belum ada.
  static String? get profilePhoto {
    return _prefs.getString(_keyProfilePhoto);
  }

  /// Menghapus path foto profil yang tersimpan.
  static Future<void> removeProfilePhoto() async {
    await _prefs.remove(_keyProfilePhoto);
  }

  // --- HELPER DATA DIRI ---
  static Future<void> saveBirthDate(String date) async => await _prefs.setString(_keyUserBirthDate, date);
  static String get userBirthDate => _prefs.getString(_keyUserBirthDate) ?? '';

  static Future<void> saveGender(String gender) async => await _prefs.setString(_keyUserGender, gender);
  static String get userGender => _prefs.getString(_keyUserGender) ?? '';

  static Future<void> saveBloodType(String bloodType) async => await _prefs.setString(_keyUserBloodType, bloodType);
  static String get userBloodType => _prefs.getString(_keyUserBloodType) ?? '';

  static Future<void> saveAllergies(String allergies) async => await _prefs.setString(_keyUserAllergies, allergies);
  static String get userAllergies => _prefs.getString(_keyUserAllergies) ?? '';

  // --- HELPER PENGATURAN NOTIFIKASI ---
  static Future<void> setNotificationGlobal(bool value) async => await _prefs.setBool(_keyNotificationGlobal, value);
  static bool get notificationGlobal => _prefs.getBool(_keyNotificationGlobal) ?? true;

  static Future<void> setNotificationSound(bool value) async => await _prefs.setBool(_keyNotificationSound, value);
  static bool get notificationSound => _prefs.getBool(_keyNotificationSound) ?? true;

  static Future<void> setNotificationVibration(bool value) async => await _prefs.setBool(_keyNotificationVibration, value);
  static bool get notificationVibration => _prefs.getBool(_keyNotificationVibration) ?? true;

  static Future<void> setNotificationSnooze(int minutes) async => await _prefs.setInt(_keyNotificationSnooze, minutes);
  static int get notificationSnooze => _prefs.getInt(_keyNotificationSnooze) ?? 10; // Default 10 menit

  /// Menyimpan path nada dering alarm sekaligus label tampilannya bersamaan,
  /// supaya penjadwal (scheduler) dan UI tidak pernah tidak sinkron.
  static Future<void> setAlarmSound(String path, String name) async {
    await _prefs.setString(_keyAlarmSound, path);
    await _prefs.setString(_keyAlarmSoundName, name);
  }

  static String get alarmSound => _prefs.getString(_keyAlarmSound) ?? defaultAlarmSound;
  static String get alarmSoundName => _prefs.getString(_keyAlarmSoundName) ?? defaultAlarmSoundName;

  // --- HELPER KONTAK DARURAT ---
  static Future<void> saveEmergencyContacts(String jsonString) async => await _prefs.setString(_keyEmergencyContacts, jsonString);
  static String get emergencyContacts => _prefs.getString(_keyEmergencyContacts) ?? '[]';

  static Future<void> logOut() async {
    await _prefs.remove(_keyIsLogin);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserEmail);

    // Hapus juga data pribadi (PII) per pengguna. Ini menyimpan cache profil
    // medis dan foto satu akun; jika dibiarkan, data pengguna sebelumnya bisa
    // bocor ke akun berikutnya yang login di perangkat bersama. Salinan
    // permanennya ada di Firestore dan akan diambil lagi ke cache saat login
    // berikutnya.
    await _prefs.remove(_keyProfilePhoto);
    await _prefs.remove(_keyUserBirthDate);
    await _prefs.remove(_keyUserGender);
    await _prefs.remove(_keyUserBloodType);
    await _prefs.remove(_keyUserAllergies);

    // Pengaturan notifikasi (global/suara/getar/snooze) adalah preferensi tingkat
    // perangkat, bukan data per pengguna, jadi sengaja dibiarkan tetap tersimpan.
  }
}
