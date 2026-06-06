import '../models.dart';
import 'cms_remote_datasource.dart';
import '../../../core/network/response_parser.dart';

class CmsRepository {
  final CmsRemoteDataSource remote;
  CmsRepository({required this.remote});

  Future<List<CmsPage>> listPages() async {
    final resp = await remote.fetchPages();
    if (resp.statusCode == 200) {
      final parsed = parseListResponse(resp);
      return parsed.map((e) {
        if (e is Map) return CmsPage.fromJson(Map<String, dynamic>.from(e));
        return CmsPage.fromJson(<String, dynamic>{});
      }).toList();
    }
    return [];
  }

  Future<CmsPage?> getPage(String slug) async {
    final resp = await remote.fetchPage(slug);
    if (resp.statusCode == 200) {
      final map = parseMapResponse(resp);
      return CmsPage.fromJson(map);
    }
    return null;
  }
}
