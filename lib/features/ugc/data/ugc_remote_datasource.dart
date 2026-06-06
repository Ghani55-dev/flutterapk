import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class UGCRemoteDataSource {
  final ApiClient apiClient;

  UGCRemoteDataSource({required this.apiClient});

  Future<Response> sendOtp({required String phone}) {
    return apiClient.dio.post('/ugc/send-otp/', data: {'phone': phone});
  }

  Future<Response> verifyOtp({required String phone, required String otp}) {
    return apiClient.dio.post('/ugc/verify-otp/', data: {'phone': phone, 'otp': otp});
  }

  Future<Response> submit(Map<String, dynamic> payload) {
    return apiClient.dio.post('/ugc/submit/', data: payload);
  }

  Future<Response> uploadMedia({
    required String filePath,
    required String contentType,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'content_type': contentType,
    });
    return apiClient.dio.post('/ugc/upload-media/', data: formData, onSendProgress: onSendProgress);
  }

  Future<Response> fetchFeed({String? cursor}) {
    return apiClient.dio.get(
      '/ugc/feed/',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
  }

  Future<Response> report({required String ugcId, required String reason}) {
    return apiClient.dio.post('/ugc/report/', data: {'ugc_id': ugcId, 'reason': reason});
  }
}
