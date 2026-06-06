import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AdsRemoteDataSource {
  final ApiClient apiClient;
  AdsRemoteDataSource({required this.apiClient});

  Future<Response> fetchAds({required String zone, String? state, String? district, String? city, double? lat, double? lng}) async {
    final Map<String, dynamic> params = {'zone': zone};
    if (state != null) params['state'] = state;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
    }
    return apiClient.dio.get('/ads/', queryParameters: params);
  }

  Future<Response> postEvent(Map<String, dynamic> payload) async {
    return apiClient.dio.post('/ads/event/', data: payload);
  }
}
