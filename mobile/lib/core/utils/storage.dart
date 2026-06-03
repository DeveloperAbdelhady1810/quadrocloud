import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AppStorage {
  static const _secure = FlutterSecureStorage();

  static Future<String?> getToken() => _secure.read(key: AppConstants.tokenKey);
  static Future<void> setToken(String t) => _secure.write(key: AppConstants.tokenKey, value: t);
  static Future<void> clearToken() => _secure.delete(key: AppConstants.tokenKey);

  static Future<String?> getClientJson() => _secure.read(key: AppConstants.clientKey);
  static Future<void> setClientJson(String j) => _secure.write(key: AppConstants.clientKey, value: j);
  static Future<void> clearAll() => _secure.deleteAll();

  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.localeKey) ?? 'ar';
  }

  static Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.localeKey, locale);
  }
}
