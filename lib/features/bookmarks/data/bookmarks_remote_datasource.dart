import '../../../core/network/api_client.dart';

class BookmarksRemoteDataSource {
  final ApiClient apiClient;
  BookmarksRemoteDataSource({required this.apiClient});

  Future fetchBookmarks() async => apiClient.dio.get('/bookmarks/');
  Future removeBookmark(String id) async => apiClient.dio.delete('/bookmarks/$id/');
}
