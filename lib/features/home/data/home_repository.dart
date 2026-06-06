import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../core/storage/secure_storage_service.dart';
import 'models.dart';
import 'home_remote_datasource.dart';
import '../../../core/network/response_parser.dart';
import '../../reels/models.dart';
import '../../epaper/models.dart';

class HomeRepository {
  final HomeRemoteDataSource remote;
  final SecureStorageService storage;

  static const _feedCacheKey = 'feed_cache_v1';

  HomeRepository({required this.remote, required this.storage});

  Future<PaginatedArticles> getFeed({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? language,
    String? state,
    String? district,
    String? city,
    double? lat,
    double? lng,
  }) async {
    final resp = await remote.fetchFeed(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
      language: language,
      state: state,
      district: district,
      city: city,
      lat: lat,
      lng: lng,
    );
    try {
      if (kDebugMode) debugPrint('[REQUEST URL] ${resp.requestOptions.uri}');
    } catch (_) {}
    // Debug: log response shape
    try {
      // Print a short preview to avoid huge logs
      debugPrint('Feed Response [status=${resp.statusCode}]: ${resp.data.runtimeType}');
      debugPrint('Feed Response preview: ${resp.data is String ? resp.data.toString().substring(0, resp.data.toString().length > 400 ? 400 : resp.data.toString().length) : resp.data}');
    } catch (_) {}
    final Map<String, dynamic> body = ApiResponseParser.extractMap(resp);
    try {
      final parsed = PaginatedArticles.fromJson(body);
      if (kDebugMode) debugPrint('[ITEM COUNT] ${parsed.results.length}');
    } catch (_) {}
    // cache first page
    if (page == 1 && body.isNotEmpty) {
      try {
        await storage.write(_feedCacheKey, json.encode(body));
      } catch (_) {}
    }
    return PaginatedArticles.fromJson(body);
  }

  Future<List<Article>> getFeatured({String? state, String? district, String? city, double? lat, double? lng}) async {
    final resp = await remote.fetchFeatured(state: state, district: district, city: city, lat: lat, lng: lng);
    try {
      debugPrint('Featured Response [status=${resp.statusCode}]: ${resp.data.runtimeType}');
      debugPrint('Featured Response preview: ${resp.data is String ? resp.data.toString().substring(0, resp.data.toString().length > 400 ? 400 : resp.data.toString().length) : resp.data}');
    } catch (_) {}
    final parsed = ApiResponseParser.extractList(resp);
    return parsed.map((e) {
      if (e is Map) return Article.fromJson(Map<String, dynamic>.from(e));
      return Article.fromJson(<String, dynamic>{});
    }).toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final resp = await remote.fetchCategories();
    try {
      debugPrint('Categories Response [status=${resp.statusCode}]: ${resp.data.runtimeType}');
      debugPrint('Categories Response preview: ${resp.data is String ? resp.data.toString().substring(0, resp.data.toString().length > 400 ? 400 : resp.data.toString().length) : resp.data}');
    } catch (_) {}
    final parsed = ApiResponseParser.extractList(resp);
    return parsed.map((e) {
      if (e is Map) return CategoryModel.fromJson(Map<String, dynamic>.from(e));
      return CategoryModel.fromJson(<String, dynamic>{});
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getLiveNews() async {
    final resp = await remote.fetchLive();
    _logEndpoint('Live news', resp);
    return ApiResponseParser.extractList(resp);
  }

  Future<Map<String, dynamic>?> getQuote() async {
    final resp = await remote.fetchQuote();
    _logEndpoint('Quote', resp);
    final map = ApiResponseParser.extractMap(resp);
    return map.isEmpty ? null : map;
  }

  Future<List<VideoItem>> getVideoPreviews() async {
    final resp = await remote.fetchVideoFeed();
    _logEndpoint('Video feed', resp);
    return ApiResponseParser.extractList(resp).map((e) => VideoItem.fromJson(e)).where((e) => e.url.isNotEmpty).toList();
  }

  Future<List<VideoItem>> getShortsPreviews() async {
    final resp = await remote.fetchShortsFeed();
    _logEndpoint('Shorts feed', resp);
    return ApiResponseParser.extractList(resp).map((e) => VideoItem.fromJson(e)).where((e) => e.url.isNotEmpty).toList();
  }

  Future<List<Epaper>> getEpapers() async {
    final resp = await remote.fetchEpapers();
    _logEndpoint('Epapers', resp);
    return ApiResponseParser.extractList(resp).map((e) => Epaper.fromJson(e)).where((e) => e.title.isNotEmpty).toList();
  }

  Future<List<Article>> getRecommendations() async {
    final resp = await remote.fetchRecommendations();
    _logEndpoint('Recommendations', resp);
    return ApiResponseParser.extractList(resp).map((e) => Article.fromJson(e)).where((e) => e.title.isNotEmpty).toList();
  }

  Future<List<Map<String, dynamic>>> getCmsBlocks() async {
    final blocks = <Map<String, dynamic>>[];
    for (final slug in const ['announcements', 'about', 'terms', 'privacy']) {
      try {
        final resp = await remote.fetchCmsBlock(slug);
        _logEndpoint('CMS $slug', resp);
        final map = ApiResponseParser.extractMap(resp);
        if (map.isNotEmpty) blocks.add(map);
      } catch (e) {
        if (kDebugMode) debugPrint('CMS $slug load failed: $e');
      }
    }
    return blocks;
  }

  Future<bool> getTtsAvailability() async {
    try {
      final resp = await remote.fetchTtsProbe();
      _logEndpoint('TTS stats', resp);
      return (resp.statusCode ?? 0) < 500;
    } catch (e) {
      if (kDebugMode) debugPrint('TTS availability failed: $e');
      return true;
    }
  }

  Future<PaginatedArticles?> getCachedFeed() async {
    final raw = await storage.read(_feedCacheKey);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> body = json.decode(raw);
      return PaginatedArticles.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  void _logEndpoint(String label, dynamic resp) {
    try {
      final list = ApiResponseParser.extractList(resp);
      debugPrint('[$label] URL=${resp.requestOptions.uri} STATUS=${resp.statusCode} PAYLOAD=${resp.data.runtimeType} PARSED_COUNT=${list.length}');
    } catch (_) {}
  }
}
