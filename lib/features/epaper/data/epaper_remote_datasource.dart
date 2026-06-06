import '../../../core/network/api_client.dart';

class EpaperRemoteDataSource {
  final ApiClient apiClient;
  EpaperRemoteDataSource({required this.apiClient});

  Future fetchList() async => apiClient.dio.get('/articles/epapers/');
  Future fetchDetail(String id) async => apiClient.dio.get('/articles/epapers/$id/');
}
