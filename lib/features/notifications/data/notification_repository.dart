import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/storage/secure_storage_service.dart';
import 'notification_models.dart';
import 'notification_remote_datasource.dart';

class NotificationRepository {
  static const _inboxCacheKey = 'notification_inbox_cache_v1';

  final NotificationRemoteDataSource remote;
  final SecureStorageService storage;

  NotificationRepository({required this.remote, required this.storage});

  Future<NotificationInboxPage> fetchInbox({String? cursor}) async {
    final response = await remote.fetchInbox(cursor: cursor);
    final payload = _extractMap(response);
    final page = NotificationInboxPage.fromJson(payload);
    if (cursor == null || cursor.isEmpty) {
      await storage.write(_inboxCacheKey, json.encode(page.toJson()));
    }
    return page;
  }

  Future<NotificationInboxPage?> getCachedInbox() async {
    final raw = await storage.read(_inboxCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        return NotificationInboxPage.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  Future<int> fetchUnreadCount() async {
    final response = await remote.fetchUnreadCount();
    final payload = _extractMap(response);
    final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : payload;
    final value = data['unread_count'] ?? data['count'] ?? data['total'] ?? 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<NotificationInboxItem> fetchNotification(String id) async {
    final response = await remote.fetchNotification(id);
    final payload = _extractMap(response);
    final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : payload;
    return NotificationInboxItem.fromJson(data);
  }

  Future<void> markRead(String id) async {
    await remote.markRead(id);
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
