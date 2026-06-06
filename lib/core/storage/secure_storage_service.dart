import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_interface.dart';

class SecureStorageService implements SecureStorageInterface {
  final FlutterSecureStorage _storage;
  SecureStorageService._(this._storage);

  factory SecureStorageService() => SecureStorageService._(const FlutterSecureStorage());

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
