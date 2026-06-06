import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class VideoRemoteDataSource {
  final ApiClient apiClient;
  VideoRemoteDataSource({required this.apiClient});

  Future<Response> fetchVideoFeed({
    int page = 1,
    int pageSize = 20,
    String? state,
    String? district,
    String? city,
    double? lat,
    double? lng,
  }) async {
    final Map<String, dynamic> params = {'page': page, 'page_size': pageSize};
    if (state != null) params['state'] = state;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
    }
    return apiClient.dio.get('/articles/video-feed/', queryParameters: params);
  }

  Future<Response> fetchShortsFeed({
    int page = 1,
    int pageSize = 20,
    String? state,
    String? district,
    String? city,
    double? lat,
    double? lng,
  }) async {
    final Map<String, dynamic> params = {'page': page, 'page_size': pageSize};
    if (state != null) params['state'] = state;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
    }
    return apiClient.dio.get('/articles/shorts-feed/', queryParameters: params);
  }
}
