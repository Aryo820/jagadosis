import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyUserName = "userName";
  static const _keyUserEmail = "userEmail";

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

  static Future<void> logOut() async {
    await _prefs.remove(_keyIsLogin);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserEmail);
  }
}
