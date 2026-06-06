import 'package:flutter/foundation.dart';
import '../../reels/models.dart';
import 'video_remote_datasource.dart';
import '../../../core/network/response_parser.dart';

class VideoRepository {
  final VideoRemoteDataSource remote;

  VideoRepository({required this.remote});

  Future<List<VideoItem>> fetchVideos({
    int page = 1,
    int pageSize = 20,
    String? state,
    String? district,
    String? city,
    double? lat,
    double? lng,
  }) async {
    final resp = await remote.fetchVideoFeed(page: page, pageSize: pageSize, state: state, district: district, city: city, lat: lat, lng: lng);
    try {
      debugPrint('Video Feed Request: page=$page size=$pageSize state=$state district=$district city=$city');
      debugPrint('Video Feed Response [path=${resp.requestOptions.path}] status=${resp.statusCode} type=${resp.data.runtimeType}');
    } catch (_) {}
    final parsed = ApiResponseParser.extractList(resp);
    return parsed.map((e) {
      if (e is Map) return VideoItem.fromJson(Map<String, dynamic>.from(e));
      return VideoItem.fromJson(<String, dynamic>{});
    }).toList();
  }

  Future<List<VideoItem>> fetchShorts({
    int page = 1,
    int pageSize = 20,
    String? state,
    String? district,
    String? city,
    double? lat,
    double? lng,
  }) async {
    final resp = await remote.fetchShortsFeed(page: page, pageSize: pageSize, state: state, district: district, city: city, lat: lat, lng: lng);
    try {
      debugPrint('Shorts Feed [${resp.requestOptions.path}] status=${resp.statusCode} type=${resp.data.runtimeType}');
    } catch (_) {}
    final parsed = ApiResponseParser.extractList(resp);
    return parsed.map((e) {
      if (e is Map) return VideoItem.fromJson(Map<String, dynamic>.from(e));
      return VideoItem.fromJson(<String, dynamic>{});
    }).toList();
  }
}
