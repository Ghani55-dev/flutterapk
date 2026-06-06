import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'models.dart';
import '../../../core/network/response_parser.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource({required ApiClient apiClient}) : _dio = apiClient.dio;

  Future<AuthTokens> login({required String email, required String password, required String deviceId, String? fcmToken}) async {
    final resp = await _dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
      'device_type': _deviceType(),
      if (fcmToken != null) 'fcm_token': fcmToken,
    });
    final map = _dataMap(resp);
    return AuthTokens.fromJson(map);
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String name,
    String preferredLanguage = 'en',
    required String deviceId,
    String? fcmToken,
  }) async {
    final resp = await _dio.post('/auth/register/', data: {
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'full_name': name,
      'preferred_language': preferredLanguage,
      'device_id': deviceId,
      'device_type': _deviceType(),
      if (fcmToken != null) 'fcm_token': fcmToken,
    });
    final map = _dataMap(resp);
    return AuthTokens.fromJson(map);
  }

  Future<AuthTokens> refreshToken({required String refresh, required String deviceId}) async {
    final resp = await _dio.post('/auth/token/refresh/', data: {
      'refresh': refresh,
      'device_id': deviceId,
      'device_type': _deviceType(),
    });
    final map = _dataMap(resp);
    return AuthTokens.fromJson(map);
  }

  Future<void> logout({required String refresh}) async {
    await _dio.post('/auth/logout/', data: {'refresh': refresh, 'logout_all_devices': false});
  }

  Future<UserModel> me({required String accessToken}) async {
    final resp = await _dio.get('/auth/me/', options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
    final map = _dataMap(resp);
    return UserModel.fromJson(map);
  }

  Future<Map<String, dynamic>> requestPasswordReset({required String email}) async {
    final resp = await _dio.post('/auth/password/reset/request/', data: {'email': email});
    return _dataMap(resp);
  }

  Future<Map<String, dynamic>> verifyPasswordReset({required String email, required String token}) async {
    final resp = await _dio.post('/auth/password/reset/verify/', data: {'email': email, 'token': token});
    return _dataMap(resp);
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final resp = await _dio.post('/auth/password/reset/confirm/', data: {
      'email': email,
      'token': token,
      'new_password': newPassword,
      'new_password_confirm': newPasswordConfirm,
    });
    return _dataMap(resp);
  }

  Map<String, dynamic> _dataMap(Response resp) {
    final raw = parseMapResponse(resp);
    final data = raw['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return raw;
  }

  String _deviceType() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}
