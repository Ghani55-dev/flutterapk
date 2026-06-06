import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../features/home/data/models.dart';
import 'search_remote_datasource.dart';
import '../../../core/network/response_parser.dart';

class SearchRepository {
  static const _historyKey = 'search_history_v1';
  final SearchRemoteDataSource remote;
  final SecureStorageService storage;

  SearchRepository({required this.remote, required this.storage});

  Future<PaginatedArticles> search({
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
    final resp = await remote.search(q: q, page: page, pageSize: pageSize, category: category, state: state, district: district, city: city, lat: lat, lng: lng, cancelToken: cancelToken);
    try {
      if (kDebugMode) debugPrint('Search Request: q=$q page=$page size=$pageSize category=$category state=$state district=$district city=$city');
      if (kDebugMode) debugPrint('Search Response [status=${resp.statusCode}] type=${resp.data.runtimeType}');
    } catch (_) {}
    final map = parseMapResponse(resp);
    return PaginatedArticles.fromJson(map);
  }

  // Simple local history persistence
  Future<List<String>> getHistory() async {
    final raw = await storage.read(_historyKey);
    if (raw == null) return [];
    try {
      final decoded = json.decode(raw);
      if (decoded is List) return decoded.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> addHistory(String q, {int cap = 20}) async {
    final list = await getHistory();
    final trimmed = list.where((e) => e.trim().isNotEmpty && e != q).toList();
    trimmed.insert(0, q);
    final capped = trimmed.take(cap).toList();
    await storage.write(_historyKey, json.encode(capped));
  }

  Future<void> removeHistory(String q) async {
    final list = await getHistory();
    final filtered = list.where((e) => e != q).toList();
    await storage.write(_historyKey, json.encode(filtered));
  }

  Future<void> clearHistory() async {
    await storage.delete(_historyKey);
  }
}
