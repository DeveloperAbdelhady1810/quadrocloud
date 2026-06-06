class AppConstants {
  // static const String baseUrl = 'http://192.168.1.4:8080/api/v1';
  static const String baseUrl = 'https://management.quadrocloud.net/api/v1';
  static const String tokenKey = 'auth_token';
  static const String clientKey = 'client_data';
  static const String localeKey = 'app_locale';

  /// Derives the Laravel public storage URL from baseUrl.
  /// e.g. http://192.168.1.8:8080/api/v1 → http://192.168.1.8:8080/storage
  static String get storageUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}/storage';
  }
}
