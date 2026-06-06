import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage_service.dart';
import 'ugc_models.dart';
import 'ugc_remote_datasource.dart';

class UGCRepository {
  static const _feedCacheKey = 'ugc_feed_cache_v1';

  final UGCRemoteDataSource remote;
  final SecureStorageService storage;

  UGCRepository({required this.remote, required this.storage});

  Future<void> sendOtp({required String phone}) async {
    await remote.sendOtp(phone: phone);
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    await remote.verifyOtp(phone: phone, otp: otp);
  }

  Future<UGCSubmissionResult> submit({
    required String title,
    required String description,
    required String category,
    required Map<String, String> location,
    required String contentType,
    List<String> mediaIds = const [],
  }) async {
    final response = await remote.submit({
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'content_type': contentType,
      if (mediaIds.isNotEmpty) 'media_ids': mediaIds,
    });
    return UGCSubmissionResult.fromJson(_extractMap(response));
  }

  Future<UGCMediaUpload> uploadMedia({
    required String filePath,
    required String contentType,
    ProgressCallback? onSendProgress,
  }) async {
    final response = await remote.uploadMedia(filePath: filePath, contentType: contentType, onSendProgress: onSendProgress);
    return UGCMediaUpload.fromJson(_extractMap(response));
  }

  Future<UGCFeedPage> fetchFeed({String? cursor}) async {
    final response = await remote.fetchFeed(cursor: cursor);
    final page = UGCFeedPage.fromJson(_extractMap(response));
    if (cursor == null || cursor.isEmpty) {
      await storage.write(_feedCacheKey, json.encode(page.toJson()));
    }
    return page;
  }

  Future<UGCFeedPage?> getCachedFeed() async {
    final raw = await storage.read(_feedCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) return UGCFeedPage.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {}
    return null;
  }

  Future<void> report({required String ugcId, required String reason}) async {
    await remote.report(ugcId: ugcId, reason: reason);
  }

  bool isNetworkError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
    }
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') || text.contains('connection') || text.contains('network') || text.contains('timeout');
  }

  Map<String, dynamic> _extractMap(Response response) {
    dynamic raw = response.data;
    if (raw is String) {
      try {
        raw = json.decode(raw);
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }
}
