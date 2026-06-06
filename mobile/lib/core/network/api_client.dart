import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  /// Set this in main() after the router is ready.
  /// Called automatically when the server returns 401.
  static void Function()? onUnauthorized;

  final _storage = const FlutterSecureStorage();
  Dio? _dio;

  Dio get dio {
    assert(_dio != null, 'ApiClient.init() must be called before use');
    return _dio!;
  }

  Future<void> init() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final t = await _storage.read(key: AppConstants.tokenKey);
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token is invalid or expired — clear it and send user to login
          await _storage.delete(key: AppConstants.tokenKey);
          _dio!.options.headers.remove('Authorization');
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  void setToken(String token) {
    _dio?.options.headers['Authorization'] = 'Bearer $token';
    _storage.write(key: AppConstants.tokenKey, value: token);
  }

  void clearToken() {
    _dio?.options.headers.remove('Authorization');
    _storage.delete(key: AppConstants.tokenKey);
  }
}
