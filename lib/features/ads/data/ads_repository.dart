import 'package:flutter/foundation.dart';
import '../../ads/models.dart';
import 'ads_remote_datasource.dart';
import '../../../core/network/response_parser.dart';

class AdsRepository {
  final AdsRemoteDataSource remote;
  final Set<String> _impressionSent = {};
  AdsRepository({required this.remote});

  Future<List<AdItem>> fetchAds({String zone = 'feed', String? state, String? district, String? city, double? lat, double? lng}) async {
    final resp = await remote.fetchAds(zone: zone, state: state, district: district, city: city, lat: lat, lng: lng);
    try {
      if (kDebugMode) debugPrint('Ads Request: zone=$zone state=$state district=$district city=$city');
      if (kDebugMode) debugPrint('Ads Response [status=${resp.statusCode}] type=${resp.data.runtimeType}');
    } catch (_) {}
    final parsed = parseListResponse(resp);
    return parsed.map((e) {
      if (e is Map) return AdItem.fromJson(Map<String, dynamic>.from(e));
      return AdItem.fromJson(<String, dynamic>{});
    }).toList();
  }

  // Impression: ensure sent once per ad id per session
  Future<void> trackImpression(String adId) async {
    if (_impressionSent.contains(adId)) return;
    _impressionSent.add(adId);
    try {
      await remote.postEvent({'ad_id': adId, 'event': 'impression'});
    } catch (_) {}
  }

  Future<void> trackClick(String adId, String url) async {
    try {
      await remote.postEvent({'ad_id': adId, 'event': 'click', 'url': url});
    } catch (_) {}
  }
}
