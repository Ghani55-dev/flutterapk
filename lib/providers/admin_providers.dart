import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/storage/secure_storage_service.dart';

// Keys for storing admin state
class AdminStorage {
  static const _accessKey = 'admin_access_token';
  static const _refreshKey = 'admin_refresh_token';
  static const _userKey = 'admin_user_data';

  final SecureStorageService _storage;
  AdminStorage(this._storage);

  Future<void> saveTokens({
    required String access,
    required String refresh,
    required Map<String, dynamic> user,
  }) async {
    await _storage.write(_accessKey, access);
    await _storage.write(_refreshKey, refresh);
    await _storage.write(_userKey, json.encode(user));
  }

  Future<String?> getAccessToken() => _storage.read(_accessKey);
  Future<String?> getRefreshToken() => _storage.read(_refreshKey);

  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await _storage.read(_userKey);
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
    await _storage.delete(_userKey);
  }
}

// Admin Auth States
enum AdminAuthStatus { unknown, authenticated, unauthenticated }

class AdminAuthState {
  final AdminAuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;

  AdminAuthState({required this.status, this.user, this.error});

  AdminAuthState.unknown() : this(status: AdminAuthStatus.unknown);
  AdminAuthState.unauthenticated({String? error})
    : this(status: AdminAuthStatus.unauthenticated, error: error);
  AdminAuthState.authenticated(Map<String, dynamic> user)
    : this(status: AdminAuthStatus.authenticated, user: user);
}

// Providers
final adminStorageProvider = Provider<AdminStorage>((ref) {
  final baseStorage = SecureStorageService();
  return AdminStorage(baseStorage);
});

final adminAuthNotifierProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
      final storage = ref.watch(adminStorageProvider);
      return AdminAuthNotifier(storage);
    });

// Admin Auth Controller
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminStorage _storage;
  final StreamController<void> _changesController =
      StreamController.broadcast();

  AdminAuthNotifier(this._storage) : super(AdminAuthState.unknown()) {
    checkAuth();
  }

  Stream<void> get changes => _changesController.stream;

  Future<void> checkAuth() async {
    final access = await _storage.getAccessToken();
    final user = await _storage.getUserData();
    if (access != null && user != null) {
      state = AdminAuthState.authenticated(user);
    } else {
      state = AdminAuthState.unauthenticated();
    }
    _changesController.add(null);
  }

  Future<bool> login({required String email, required String password}) async {
    state = AdminAuthState.unknown();
    try {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://incite-backend.onrender.com'),
      );
      final resp = await dio.post(
        '/api/v1/auth/login/',
        data: {'email': email, 'password': password, 'device_id': 'web-admin'},
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data;
        // The endpoint returns token details
        final payload = data['data'] ?? data;
        final access = payload['access']?.toString() ?? '';
        final refresh = payload['refresh']?.toString() ?? '';
        final userPayload = payload['user'];
        final user = userPayload is Map
            ? Map<String, dynamic>.from(userPayload)
            : Map<String, dynamic>.from(payload as Map);

        final isAdmin = _readAdminFlag(user);
        if (!isAdmin) {
          state = AdminAuthState.unauthenticated(
            error: 'Access denied: User is not an administrator.',
          );
          return false;
        }

        await _storage.saveTokens(access: access, refresh: refresh, user: user);
        state = AdminAuthState.authenticated(user);
        _changesController.add(null);
        return true;
      } else {
        state = AdminAuthState.unauthenticated(
          error: 'Invalid response from authentication server.',
        );
        return false;
      }
    } catch (e) {
      String msg = 'Authentication failed. Please verify credentials.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          msg = data['message'].toString();
        } else if (data is Map && data.containsKey('error')) {
          msg = data['error'].toString();
        }
      }
      state = AdminAuthState.unauthenticated(error: msg);
      return false;
    }
  }

  /// Called when the regular user login detects an admin account.
  /// Populates admin storage with the already-obtained tokens so the
  /// admin panel becomes accessible without a second API call.
  Future<void> loginWithTokens({
    required String access,
    required String refresh,
    required Map<String, dynamic> user,
  }) async {
    await _storage.saveTokens(access: access, refresh: refresh, user: user);
    state = AdminAuthState.authenticated(user);
    _changesController.add(null);
  }

  Future<void> logout() async {
    await _storage.clear();
    state = AdminAuthState.unauthenticated();
    _changesController.add(null);
  }

  @override
  void dispose() {
    _changesController.close();
    super.dispose();
  }
}

bool _readAdminFlag(Map<String, dynamic> map) {
  bool truthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'admin' ||
        normalized == 'administrator' ||
        normalized == 'superuser' ||
        normalized == 'staff';
  }

  if (truthy(map['is_admin']) ||
      truthy(map['is_staff']) ||
      truthy(map['is_superuser'])) {
    return true;
  }

  for (final key in ['role', 'user_type', 'account_type']) {
    if (truthy(map[key])) return true;
  }

  final roles = map['roles'] ?? map['groups'] ?? map['permissions'];
  if (roles is Iterable) {
    return roles.any(truthy);
  }

  return false;
}

// Dio API Client for Admin Requests
final adminApiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(adminStorageProvider);
  final authNotifier = ref.watch(adminAuthNotifierProvider.notifier);

  final baseOptions = BaseOptions(
    baseUrl: 'https://incite-backend.onrender.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  );

  final dio = Dio(baseOptions);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        final status = err.response?.statusCode;
        if (status == 401) {
          final options = err.requestOptions;
          if (options.extra['_isRetry'] == true) {
            authNotifier.logout();
            handler.next(err);
            return;
          }

          final refresh = await storage.getRefreshToken();
          if (refresh == null || refresh.isEmpty) {
            authNotifier.logout();
            handler.next(err);
            return;
          }

          try {
            final refreshDio = Dio(
              BaseOptions(baseUrl: 'https://incite-backend.onrender.com'),
            );
            final refreshResp = await refreshDio.post(
              '/api/v1/auth/token/refresh/',
              data: {'refresh': refresh, 'device_id': 'web-admin'},
            );

            if (refreshResp.statusCode == 200 ||
                refreshResp.statusCode == 201) {
              final data = refreshResp.data;
              final payload = data['data'] ?? data;
              final access = payload['access']?.toString() ?? '';
              final newRefresh = payload['refresh']?.toString() ?? refresh;
              final user = await storage.getUserData() ?? {};

              await storage.saveTokens(
                access: access,
                refresh: newRefresh,
                user: user,
              );

              // Retry original request
              options.headers['Authorization'] = 'Bearer $access';
              options.extra['_isRetry'] = true;

              final finalDio = Dio(BaseOptions(baseUrl: options.baseUrl));
              final retryResponse = await finalDio.request(
                options.path,
                data: options.data,
                queryParameters: options.queryParameters,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                  extra: options.extra,
                ),
              );
              handler.resolve(retryResponse);
              return;
            }
          } catch (_) {
            authNotifier.logout();
            handler.next(err);
            return;
          }
        }
        handler.next(err);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[Admin API] ${obj.toString()}'),
      ),
    );
  }

  return dio;
});
