import 'package:flutter/foundation.dart';
import 'models.dart';
import 'auth_remote_datasource.dart';
import 'token_manager.dart';

class AuthRepository {
  final TokenManager tokenManager;
  final AuthRemoteDataSource _remote;

  AuthRepository({required AuthRemoteDataSource remote, required this.tokenManager}) : _remote = remote;

  Future<UserModel?> me() async {
    final access = await tokenManager.getAccessToken();
    if (access == null) return null;
    try {
      final user = await _remote.me(accessToken: access);
      return user;
    } catch (e) {
      if (kDebugMode) debugPrint('me() failed: $e');
      return null;
    }
  }

  Future<bool> login({required String email, required String password, String? deviceId, String? fcmToken}) async {
    final resolvedDeviceId = await _resolveDeviceId(deviceId);
    final tokens = await _remote.login(email: email, password: password, deviceId: resolvedDeviceId, fcmToken: fcmToken);
    await tokenManager.persistTokens(tokens);
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String name,
    String preferredLanguage = 'en',
    String? deviceId,
    String? fcmToken,
  }) async {
    final resolvedDeviceId = await _resolveDeviceId(deviceId);
    final tokens = await _remote.register(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      name: name,
      preferredLanguage: preferredLanguage,
      deviceId: resolvedDeviceId,
      fcmToken: fcmToken,
    );
    await tokenManager.persistTokens(tokens);
    return true;
  }

  Future<void> logout() async {
    final refresh = await tokenManager.getRefreshToken();
    if (refresh != null) {
      try {
        await _remote.logout(refresh: refresh);
      } catch (_) {}
    }
    await tokenManager.clear();
  }

  Future<void> clearLocalSession() => tokenManager.clear();

  Future<Map<String, dynamic>> requestPasswordReset({required String email}) {
    return _remote.requestPasswordReset(email: email);
  }

  Future<Map<String, dynamic>> verifyPasswordReset({required String email, required String token}) {
    return _remote.verifyPasswordReset(email: email, token: token);
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) {
    return _remote.confirmPasswordReset(
      email: email,
      token: token,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  }

  Future<String> _resolveDeviceId(String? provided) async {
    if (provided != null && provided.isNotEmpty) return provided;
    final existing = await tokenManager.readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = 'varadhi-${DateTime.now().millisecondsSinceEpoch}';
    await tokenManager.saveDeviceId(generated);
    return generated;
  }
}
