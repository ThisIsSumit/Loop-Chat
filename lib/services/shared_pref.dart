import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String keyName = "Name";
  static const String keyEmail = "Email";
  static const String keyImage = "Image";
  static const String keyId = "Id";
  static const String keyUserName = "userName";
  static Future<bool> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyName, name);
  }

  static Future<bool> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyEmail, email);
  }

  static Future<bool> saveImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyImage, imageUrl);
  }

  static Future<bool> saveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyId, id);
  }

  static Future<bool> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyUserName, userName);
  }

  // Optional: Clear all
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
