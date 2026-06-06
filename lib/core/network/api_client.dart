import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

dynamic jsonDecodeSafe(String s) {
  try {
    return json.decode(s);
  } catch (_) {
    return null;
  }
}

// Lightweight network handling is provided by timeouts and controlled
// connection pools. For advanced retry logic prefer a repository-level
// retry wrapper to avoid interceptor-side request replays.

class ApiClient {
  final Dio dio;
  ApiClient._internal(this.dio);

  factory ApiClient({required String baseUrl, required Interceptor authInterceptor}) {
    final options = BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    );

    final dio = Dio(options);
    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          // Normalize path: remove any leading slash so Dio combines with baseUrl cleanly.
          // Also guard against accidental double "api/v1/api/v1" by removing a leading
          // duplicate segment when baseUrl already contains it.
          try {
            if (options.path.startsWith('/')) {
              options.path = options.path.substring(1);
            }
            final base = options.baseUrl;
            // if path begins with 'api/v1/' and base already ends with 'api/v1/', strip the leading segment
            if (base.endsWith('api/v1/') && options.path.startsWith('api/v1/')) {
              options.path = options.path.replaceFirst('api/v1/', '');
            }
          } catch (_) {}
          handler.next(options);
        },
    ));
    // Add an interceptor for debug-time request/response inspection
    if (kDebugMode) {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            // Safe headers: exclude Authorization and other sensitive keys
            final safeHeaders = <String, dynamic>{};
            options.headers.forEach((k, v) {
              try {
                final key = k.toString();
                if (key.toLowerCase().contains('auth')) return;
                final val = v is String ? (v.length > 200 ? '${v.substring(0, 200)}...' : v) : v;
                safeHeaders[key] = val;
              } catch (_) {}
            });

            final body = options.data;
            final payload = body != null ? (body is String ? body : body.toString()) : null;
            final preview = payload != null ? (payload.length > 1000 ? payload.substring(0, 1000) : payload) : null;

            debugPrint('[API REQUEST]');
            debugPrint(options.method.toString() + ' ' + options.uri.toString());
            debugPrint('params=' + options.queryParameters.toString());
            debugPrint('headers=' + safeHeaders.toString());
            if (preview != null) debugPrint('payload=' + preview);
          } catch (_) {}
          handler.next(options);
        },
        onResponse: (response, handler) {
          try {
            final respStr = response.data is String ? response.data as String : response.data.toString();
            final snippet = respStr.length > 800 ? respStr.substring(0, 800) : respStr;
            // attempt to detect parsed item count and source for debugging
            int parsedCount = 0;
            String parserSource = 'unknown';
            try {
              dynamic d = response.data;
              if (d is String) d = jsonDecodeSafe(d);
              if (d is List) {
                parsedCount = d.length;
                parserSource = 'top_list';
              }
              if (d is Map) {
                final safe = Map<String, dynamic>.from(d);
                final extracted = safe['data'] ?? safe['results'] ?? safe['items'] ?? safe['articles'];
                if (extracted is List) {
                  parsedCount = extracted.length;
                  // determine which key held the list
                  if (safe.containsKey('data') && safe['data'] is List) parserSource = 'data';
                  else if (safe.containsKey('results')) parserSource = 'results';
                  else if (safe.containsKey('items')) parserSource = 'items';
                  else if (safe.containsKey('articles')) parserSource = 'articles';
                } else if (safe.containsKey('data') && safe['data'] is Map) {
                  parserSource = 'data.map';
                } else {
                  parserSource = 'map';
                }
              }
            } catch (_) {}

            debugPrint('[API RESPONSE]');
            debugPrint('${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}');
            debugPrint('query=${response.requestOptions.queryParameters}');
            debugPrint('parser_source=$parserSource items=$parsedCount');
            debugPrint(snippet);
          } catch (e) {
            debugPrint('API response debug error: $e');
          }
          handler.next(response);
        },
        onError: (err, handler) {
          try {
              final method = err.requestOptions.method;
              final uri = err.requestOptions.uri;
              debugPrint('--- API ERROR ---> $method $uri');
              final dioErr = err;
              debugPrint('DioException: ${dioErr.type} ${dioErr.message}');
              debugPrint('Status: ${dioErr.response?.statusCode}');
            } catch (_) {}
          handler.next(err);
        },
      ));
    }
    dio.interceptors.addAll([
      authInterceptor,
      LogInterceptor(requestBody: kDebugMode, responseBody: kDebugMode),
    ]);

    // Reduce default maximum connections if running on memory-constrained devices.
    try {
      final ioAdapter = dio.httpClientAdapter as IOHttpClientAdapter;
      // `onHttpClientCreate` is deprecated; use `createHttpClient` instead.
      ioAdapter.createHttpClient = () {
        final client = HttpClient();
        client.maxConnectionsPerHost = 5;
        return client;
      };
    } catch (_) {}

    return ApiClient._internal(dio);
  }
}
