import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/storage.dart';
import 'client_model.dart';

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<ClientModel> login(String email, String password) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _handleAuthResponse(res.data);
  }

  Future<ClientModel> socialLogin({
    required String provider,
    required String token,
    String? name,
    String? email,
    String? userId,
  }) async {
    final res = await _api.dio.post('/auth/social', data: {
      'provider': provider,
      'token': token,
      if (name != null && name.isNotEmpty) 'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (userId != null) 'user_id': userId,
    });
    return _handleAuthResponse(res.data);
  }

  Future<ClientModel> otpLogin(String email, String otp) async {
    final res = await _api.dio.post('/auth/otp-login', data: {
      'email': email,
      'otp': otp,
    });
    return _handleAuthResponse(res.data);
  }

  Future<ClientModel> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final client = ClientModel.fromJson(data['client']);
    _api.setToken(token);
    await AppStorage.setClientJson(jsonEncode(client.toJson()));
    await AppStorage.setLocale(client.locale);
    // Register device for push notifications
    await NotificationService.syncToken();
    return client;
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {}
    _api.clearToken();
    await AppStorage.clearAll();
  }

  Future<void> changePassword(String current, String newPass) async {
    await _api.dio.put('/auth/password', data: {
      'current_password': current,
      'password': newPass,
      'password_confirmation': newPass,
    });
  }

  Future<void> updateFcmToken(String token) async {
    await _api.dio.put('/auth/fcm-token', data: {'fcm_token': token});
  }

  Future<void> updateLocale(String locale) async {
    await _api.dio.put('/auth/locale', data: {'locale': locale});
  }

  Future<ClientModel> updateProfile({
    String? name,
    String? phone,
    String? companyName,
    String? address,
  }) async {
    final res = await _api.dio.put('/auth/profile', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (companyName != null) 'company_name': companyName,
      if (address != null) 'address': address,
    });
    final client = ClientModel.fromJson(res.data);
    await AppStorage.setClientJson(jsonEncode(client.toJson()));
    return client;
  }

  Future<ClientModel?> getCachedClient() async {
    final json = await AppStorage.getClientJson();
    if (json == null) return null;
    return ClientModel.fromJson(jsonDecode(json));
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository(ApiClient()));
