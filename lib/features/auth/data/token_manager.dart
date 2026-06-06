import '../../../core/storage/secure_storage_service.dart';
import 'auth_local_datasource.dart';
import 'auth_remote_datasource.dart';
import 'models.dart';

class TokenManager {
  final SecureStorageService storage;
  late final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;
  Future<bool>? _refreshFuture;

  TokenManager({required this.storage, required AuthRemoteDataSource remote}) : _remote = remote {
    _local = AuthLocalDataSource(storage);
  }

  Future<String?> getAccessToken() async => (await _local.readTokens())?.access;
  Future<String?> getRefreshToken() async => (await _local.readTokens())?.refresh;

  Future<bool> refreshIfNeeded() async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final refreshFuture = _refreshTokens();
    _refreshFuture = refreshFuture;
    return refreshFuture.whenComplete(() {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    });
  }

  Future<bool> _refreshTokens() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    try {
      final deviceId = await _readOrCreateDeviceId();
      final tokens = await _remote.refreshToken(refresh: refresh, deviceId: deviceId);
      await _local.saveTokens(tokens);
      return true;
    } catch (e) {
      await _local.clearTokens();
      return false;
    }
  }

  Future<void> persistTokens(AuthTokens tokens) => _local.saveTokens(tokens);
  Future<void> clear() => _local.clearTokens();
  Future<void> saveDeviceId(String id) => _local.saveDeviceId(id);
  Future<String?> readDeviceId() => _local.readDeviceId();

  Future<String> _readOrCreateDeviceId() async {
    final existing = await readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = 'varadhi-${DateTime.now().millisecondsSinceEpoch}';
    await saveDeviceId(generated);
    return generated;
  }
}
