import 'tts_remote_datasource.dart';

class TtsRepository {
  final TtsRemoteDataSource remote;
  TtsRepository({required this.remote});

  Future<Map<String, dynamic>> requestTts({required String content, String language = 'en', required String objectType, required String objectId}) =>
      remote.requestTts(content: content, language: language, objectType: objectType, objectId: objectId);

  Future<Map<String, dynamic>> getStatus(String taskId) => remote.status(taskId);
}
