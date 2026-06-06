import '../../../core/network/api_client.dart';

class CmsRemoteDataSource {
  final ApiClient apiClient;
  CmsRemoteDataSource({required this.apiClient});

  Future fetchPages() async => apiClient.dio.get('/cms/');
  Future fetchPage(String slug) async => apiClient.dio.get('/cms/$slug/');
}
