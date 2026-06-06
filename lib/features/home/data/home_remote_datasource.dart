import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class HomeRemoteDataSource {
  final ApiClient apiClient;
  HomeRemoteDataSource({required this.apiClient});

  Future<Response> fetchFeed({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? state,
    String? district,
    String? city,
    String? language,
    double? lat,
    double? lng,
  }) async {
    final Map<String, dynamic> params = {'page': page, 'page_size': pageSize};
    if (categoryId != null) params['category'] = categoryId;
    if (language != null) params['lang'] = language;
    if (state != null) params['state'] = state;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
    }
    return apiClient.dio.get('/articles/feed/', queryParameters: params);
  }

  Future<Response> fetchFeatured({String? state, String? district, String? city, double? lat, double? lng}) async {
    final params = <String, dynamic>{};
    if (state != null) params['state'] = state;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
    }
    return apiClient.dio.get('/articles/featured/', queryParameters: params);
  }

  Future<Response> fetchCategories() async {
    return apiClient.dio.get('/categories/');
  }

  Future<Response> fetchLive() async => apiClient.dio.get('/articles/live/');
  Future<Response> fetchQuote() async => apiClient.dio.get('/quotes/random/');
  Future<Response> fetchVideoFeed({int page = 1, int pageSize = 10}) async =>
      apiClient.dio.get('/articles/video-feed/', queryParameters: {'page': page, 'page_size': pageSize});
  Future<Response> fetchShortsFeed({int page = 1, int pageSize = 10}) async =>
      apiClient.dio.get('/articles/shorts-feed/', queryParameters: {'page': page, 'page_size': pageSize});
  Future<Response> fetchEpapers() async => apiClient.dio.get('/articles/epapers/');
  Future<Response> fetchRecommendations() async => apiClient.dio.get('/articles/recommendations/');
  Future<Response> fetchCmsBlock(String slug) async => apiClient.dio.get('/cms/$slug/');
  Future<Response> fetchTtsProbe() async => apiClient.dio.get('/articles/tts/stats/');
}
