import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class PollsRemoteDataSource {
  final ApiClient apiClient;
  PollsRemoteDataSource({required this.apiClient});

  Future<Response> fetchPolls({String? state, String? district, String? city, double? lat, double? lng}) async {
    final params = <String, dynamic>{};
    if (state != null) params['state'] = state;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
    }
    return apiClient.dio.get('/polls/', queryParameters: params);
  }

  Future<Response> fetchPollDetail(String id) async => apiClient.dio.get('/polls/$id/');

  Future<Response> vote(String id, String optionId) async => apiClient.dio.post('/polls/$id/vote/', data: {'option_id': optionId});
}
