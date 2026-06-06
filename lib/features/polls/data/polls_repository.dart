import 'package:flutter/foundation.dart';

import '../../polls/models.dart';
import '../../../core/network/api_client.dart';
import 'polls_remote_datasource.dart';
import 'polls_repository_interface.dart';
import '../../../core/network/response_parser.dart';

class PollsRepository implements PollsRepositoryInterface {
  final PollsRemoteDataSource remote;
  final ApiClient apiClient;

  PollsRepository({required this.remote, required this.apiClient});

  @override
  Future<List<Poll>> getPolls({String? state, String? district, String? city, double? lat, double? lng}) async {
    final resp = await remote.fetchPolls(state: state, district: district, city: city, lat: lat, lng: lng);
    try {
      debugPrint('Polls [${resp.requestOptions.path}] status=${resp.statusCode} type=${resp.data.runtimeType}');
      debugPrint('Polls preview: ${resp.data is String ? resp.data.toString().substring(0, resp.data.toString().length > 300 ? 300 : resp.data.toString().length) : resp.data}');
    } catch (_) {}
    if (resp.statusCode == 200) {
      final parsed = parseListResponse(resp);
      return parsed.map((e) {
        if (e is Map) return Poll.fromJson(Map<String, dynamic>.from(e));
        return Poll.fromJson(<String, dynamic>{});
      }).toList();
    }
    throw Exception('Failed to load polls');
  }

  @override
  Future<Poll> getPoll(String id) async {
    final resp = await remote.fetchPollDetail(id);
    if (resp.statusCode == 200) {
      final map = parseMapResponse(resp);
      return Poll.fromJson(map);
    }
    throw Exception('Failed to load poll');
  }

  @override
  Future<Poll> vote(String pollId, String optionId) async {
    final resp = await remote.vote(pollId, optionId);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final map = parseMapResponse(resp);
      return Poll.fromJson(map);
    }
    throw Exception('Vote failed');
  }
}
