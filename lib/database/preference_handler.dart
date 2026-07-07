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

  // Data Diri Keys
  static const _keyUserBirthDate = "userBirthDate";
  static const _keyUserGender = "userGender";
  static const _keyUserBloodType = "userBloodType";
  static const _keyUserAllergies = "userAllergies";

  // Notification Settings Keys
  static const _keyNotificationGlobal = "notificationGlobal";
  static const _keyNotificationSound = "notificationSound";
  static const _keyNotificationVibration = "notificationVibration";
  static const _keyNotificationSnooze = "notificationSnooze";

  // Emergency Contacts Keys
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

  /// Saves the absolute file path of the user's profile photo.
  static Future<void> saveProfilePhoto(String path) async {
    await _prefs.setString(_keyProfilePhoto, path);
  }

  /// Returns the stored profile photo path, or null if none is set.
  static String? get profilePhoto {
    return _prefs.getString(_keyProfilePhoto);
  }

  /// Removes the stored profile photo path.
  static Future<void> removeProfilePhoto() async {
    await _prefs.remove(_keyProfilePhoto);
  }

  // --- DATA DIRI HELPERS ---
  static Future<void> saveBirthDate(String date) async => await _prefs.setString(_keyUserBirthDate, date);
  static String get userBirthDate => _prefs.getString(_keyUserBirthDate) ?? '';

  static Future<void> saveGender(String gender) async => await _prefs.setString(_keyUserGender, gender);
  static String get userGender => _prefs.getString(_keyUserGender) ?? '';

  static Future<void> saveBloodType(String bloodType) async => await _prefs.setString(_keyUserBloodType, bloodType);
  static String get userBloodType => _prefs.getString(_keyUserBloodType) ?? '';

  static Future<void> saveAllergies(String allergies) async => await _prefs.setString(_keyUserAllergies, allergies);
  static String get userAllergies => _prefs.getString(_keyUserAllergies) ?? '';

  // --- NOTIFICATION SETTINGS HELPERS ---
  static Future<void> setNotificationGlobal(bool value) async => await _prefs.setBool(_keyNotificationGlobal, value);
  static bool get notificationGlobal => _prefs.getBool(_keyNotificationGlobal) ?? true;

  static Future<void> setNotificationSound(bool value) async => await _prefs.setBool(_keyNotificationSound, value);
  static bool get notificationSound => _prefs.getBool(_keyNotificationSound) ?? true;

  static Future<void> setNotificationVibration(bool value) async => await _prefs.setBool(_keyNotificationVibration, value);
  static bool get notificationVibration => _prefs.getBool(_keyNotificationVibration) ?? true;

  static Future<void> setNotificationSnooze(int minutes) async => await _prefs.setInt(_keyNotificationSnooze, minutes);
  static int get notificationSnooze => _prefs.getInt(_keyNotificationSnooze) ?? 10; // Default 10 minutes

  // --- EMERGENCY CONTACTS HELPERS ---
  static Future<void> saveEmergencyContacts(String jsonString) async => await _prefs.setString(_keyEmergencyContacts, jsonString);
  static String get emergencyContacts => _prefs.getString(_keyEmergencyContacts) ?? '[]';

  static Future<void> logOut() async {
    await _prefs.remove(_keyIsLogin);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserEmail);

    // Clear per-user PII too. These cache one account's medical profile and
    // photo; leaving them behind would leak the previous user's data into the
    // next account that signs in on a shared device. The durable copies live in
    // Firestore and are pulled back into the cache on the next login.
    await _prefs.remove(_keyProfilePhoto);
    await _prefs.remove(_keyUserBirthDate);
    await _prefs.remove(_keyUserGender);
    await _prefs.remove(_keyUserBloodType);
    await _prefs.remove(_keyUserAllergies);

    // Notification settings (global/sound/vibration/snooze) are device-level
    // preferences, not per-user data, so they intentionally persist.
  }
}
