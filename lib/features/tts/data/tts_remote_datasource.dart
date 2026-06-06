import '../../../core/network/api_client.dart';
import '../../../core/network/response_parser.dart';

class TtsRemoteDataSource {
  final ApiClient apiClient;
  TtsRemoteDataSource({required this.apiClient});

  /// Request generation of TTS for given content.
  /// Returns server response map (may include task_id or file_url).
  Future<Map<String, dynamic>> requestTts({required String content, String language = 'en', required String objectType, required String objectId}) async {
    final resp = await apiClient.dio.post('/articles/tts/', data: {
      'content': content,
      'language': language,
      'object_type': objectType,
      'object_id': objectId,
    });
    return parseMapResponse(resp);
  }

  Future<Map<String, dynamic>> status(String taskId) async {
    final resp = await apiClient.dio.get('/articles/tts/status/$taskId/');
    return parseMapResponse(resp);
  }
}
