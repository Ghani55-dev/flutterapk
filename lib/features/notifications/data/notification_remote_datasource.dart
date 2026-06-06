import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSource({required this.apiClient});

  Future<Response> fetchInbox({String? cursor}) {
    return apiClient.dio.get(
      '/api/v1/notifications/inbox/',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
  }

  Future<Response> fetchUnreadCount() {
    return apiClient.dio.get('/api/v1/notifications/inbox/unread-count/');
  }

  Future<Response> fetchNotification(String id) {
    return apiClient.dio.get('/api/v1/notifications/inbox/$id/');
  }

  Future<Response> markRead(String id) {
    return apiClient.dio.post('/api/v1/notifications/inbox/$id/read/');
  }
}
