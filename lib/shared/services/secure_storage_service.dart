import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage wrapper using SharedPreferences.
/// Note: For production Android/iOS, consider adding flutter_secure_storage
/// with proper ATL/keychain setup. For now uses SharedPreferences.
class SecureStorageService {
  static Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
