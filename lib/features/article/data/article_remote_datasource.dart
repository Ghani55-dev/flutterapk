import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ArticleRemoteDataSource {
  final ApiClient apiClient;
  ArticleRemoteDataSource({required this.apiClient});

  Future<Response> fetchDetail(String slug) async {
    return apiClient.dio.get('/articles/$slug/');
  }

  Future<Response> toggleBookmark(String articleId) async {
    return apiClient.dio.post('/bookmarks/toggle/', data: {'article_id': articleId});
  }

  Future<Response> requestTTS(String articleId) async {
    return apiClient.dio.post('/articles/tts/', data: {'article_id': articleId});
  }

  Future<Response> fetchRelated({String? category, int pageSize = 5}) async {
    final Map<String, dynamic> params = {'page_size': pageSize};
    if (category != null) params['category'] = category;
    return apiClient.dio.get('/articles/feed/', queryParameters: params);
  }
}
