import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class SearchRemoteDataSource {
  final ApiClient apiClient;

  SearchRemoteDataSource({required this.apiClient});

  Future<Response> search({
    required String q,
    int page = 1,
    int pageSize = 20,
    String? category,
    String? state,
    String? district,
    String? city,
    double? lat,
    double? lng,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{'q': q, 'page': page, 'page_size': pageSize};
    if (category != null) params['category'] = category;
    if (state != null) params['state'] = state;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
    }
    return apiClient.dio.get('/search/', queryParameters: params, cancelToken: cancelToken);
  }
}
