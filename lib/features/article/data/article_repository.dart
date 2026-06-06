import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models.dart';
import 'article_remote_datasource.dart';
import '../../../core/network/response_parser.dart';

class ArticleRepository {
  final ArticleRemoteDataSource remote;
  final SecureStorageService storage;
  static const _cachePrefix = 'article_detail_';

  ArticleRepository({required this.remote, required this.storage});

  Future<ArticleDetail?> getCachedDetail(String slug) async {
    final raw = await storage.read('$_cachePrefix$slug');
    if (raw == null) return null;
    try {
      final Map<String, dynamic> j = json.decode(raw);
      return ArticleDetail.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<ArticleDetail> getDetail(String slug, {bool cacheFirst = true}) async {
    if (cacheFirst) {
      final cached = await getCachedDetail(slug);
      if (cached != null) return cached;
    }
    final resp = await remote.fetchDetail(slug);
    try {
      debugPrint('Article detail [${resp.requestOptions.path}] status=${resp.statusCode} type=${resp.data.runtimeType}');
      debugPrint('Article preview: ${resp.data is String ? resp.data.toString().substring(0, resp.data.toString().length > 300 ? 300 : resp.data.toString().length) : resp.data}');
    } catch (_) {}
    // Use centralized parser to safely extract map payload
    final Map<String, dynamic> payload = ApiResponseParser.extractMap(resp);
    if (payload.isNotEmpty) {
      await storage.write('$_cachePrefix$slug', json.encode(payload));
      return ArticleDetail.fromJson(Map<String, dynamic>.from(payload));
    }
    throw Exception('Failed to load article detail');
  }

  Future<bool> toggleBookmark(String articleId) async {
    final resp = await remote.toggleBookmark(articleId);
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  Future<bool> requestTTS(String articleId) async {
    final resp = await remote.requestTTS(articleId);
    return resp.statusCode == 200 || resp.statusCode == 202;
  }

  Future<List<ArticleDetail>> getRelated(String? category) async {
    final resp = await remote.fetchRelated(category: category);
    try {
      debugPrint('Related [${resp.requestOptions.path}] status=${resp.statusCode} type=${resp.data.runtimeType}');
      debugPrint('Related preview: ${resp.data is String ? resp.data.toString().substring(0, resp.data.toString().length > 300 ? 300 : resp.data.toString().length) : resp.data}');
    } catch (_) {}
    final parsed = ApiResponseParser.extractList(resp);
    return parsed.map((e) {
      if (e is Map) return ArticleDetail.fromJson(Map<String, dynamic>.from(e));
      return ArticleDetail.fromJson(<String, dynamic>{});
    }).toList();
  }
}
