import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/auth/data/auth_remote_datasource.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/token_manager.dart';
import '../features/core/data/health_repository.dart';
import '../features/startup/data/startup_preferences.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final authApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: AppConfig.backendBaseUrl, authInterceptor: InterceptorsWrapper());
});

final authRemoteProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(apiClient: ref.read(authApiClientProvider));
});

final tokenManagerProvider = Provider<TokenManager>((ref) {
  final storage = ref.read(secureStorageProvider);
  return TokenManager(storage: storage, remote: ref.read(authRemoteProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenManager = ref.read(tokenManagerProvider);
  return AuthRepository(remote: ref.read(authRemoteProvider), tokenManager: tokenManager);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenManager = ref.read(tokenManagerProvider);
  final authInterceptor = AuthInterceptor(tokenManager: tokenManager, ref: ref);
  return ApiClient(baseUrl: AppConfig.backendBaseUrl, authInterceptor: authInterceptor);
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(apiClient: ref.read(apiClientProvider));
});

final startupPreferencesProvider = Provider<StartupPreferences>((ref) {
  return StartupPreferences();
});

class AuthInterceptor extends Interceptor {
  final TokenManager tokenManager;
  final Ref ref;
  AuthInterceptor({required this.tokenManager, required this.ref});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenManager.getAccessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(dynamic err, ErrorInterceptorHandler handler) async {
    final status = (err is DioException) ? err.response?.statusCode : null;
    final opts = (err is DioException) ? err.requestOptions : null;
    final hasRetried = opts?.extra['_auth_retry'] == true;
    if (status == 401 && opts != null && !hasRetried) {
      try {
        final refreshed = await tokenManager.refreshIfNeeded();
        if (refreshed) {
          final token = await tokenManager.getAccessToken();
          if (token != null) opts.headers['Authorization'] = 'Bearer $token';
          opts.extra['_auth_retry'] = true;
          final response = await ref.read(apiClientProvider).dio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}
