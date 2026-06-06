import 'package:flutter/foundation.dart';
import 'bookmarks_remote_datasource.dart';
import '../../home/data/models.dart';
import '../../../core/network/response_parser.dart';

class BookmarksRepository {
  final BookmarksRemoteDataSource remote;
  BookmarksRepository({required this.remote});

  Future<List<Article>> fetchBookmarks() async {
    final resp = await remote.fetchBookmarks();
    try {
      if (kDebugMode) debugPrint('Bookmarks Request: ${resp.requestOptions.method} ${resp.requestOptions.path}');
      if (kDebugMode) debugPrint('Bookmarks Response [status=${resp.statusCode}] type=${resp.data.runtimeType}');
    } catch (_) {}
    if (resp.statusCode == 200) {
      final parsed = parseListResponse(resp);
      return parsed.map((e) => Article.fromJson(Map<String, dynamic>.from(e))).toList().cast<Article>();
    }
    throw Exception('Failed to load bookmarks');
  }

  Future<void> removeBookmark(String id) async {
    await remote.removeBookmark(id);
  }
}
