import '../../../core/storage/secure_storage_service.dart';
import 'models.dart';

class AuthLocalDataSource {
  final SecureStorageService storage;
  AuthLocalDataSource(this.storage);

  Future<void> saveTokens(AuthTokens tokens) async {
    await storage.write('access', tokens.access);
    await storage.write('refresh', tokens.refresh);
  }

  Future<AuthTokens?> readTokens() async {
    final a = await storage.read('access');
    final r = await storage.read('refresh');
    if (a == null || r == null) return null;
    return AuthTokens(access: a, refresh: r);
  }

  Future<void> clearTokens() async {
    await storage.delete('access');
    await storage.delete('refresh');
  }

  Future<void> saveDeviceId(String deviceId) => storage.write('device_id', deviceId);
  Future<String?> readDeviceId() => storage.read('device_id');
}
