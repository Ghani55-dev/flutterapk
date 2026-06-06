import 'package:flutter/foundation.dart';
import 'epaper_remote_datasource.dart';
import '../models.dart';
import '../../../core/network/response_parser.dart';

class EpaperRepository {
  final EpaperRemoteDataSource remote;
  EpaperRepository({required this.remote});

  Future<List<Epaper>> list() async {
    final resp = await remote.fetchList();
    try {
      if (kDebugMode) debugPrint('[EPAPER API RESPONSE] list status=${resp.statusCode} type=${resp.data.runtimeType}');
    } catch (_) {}
    if (resp.statusCode == 200) {
      final parsed = parseListResponse(resp);
      return parsed.map((e) {
        if (e is Map) return Epaper.fromJson(Map<String, dynamic>.from(e));
        return Epaper.fromJson(<String, dynamic>{});
      }).toList();
    }
    return [];
  }

  Future<Epaper?> detail(String id) async {
    final resp = await remote.fetchDetail(id);
    try {
      if (kDebugMode) debugPrint('[EPAPER API RESPONSE] detail id=$id status=${resp.statusCode} type=${resp.data.runtimeType}');
    } catch (_) {}
    if (resp.statusCode == 200) {
      final map = parseMapResponse(resp);
      return Epaper.fromJson(map);
    }
    return null;
  }
}
