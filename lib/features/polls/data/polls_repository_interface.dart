import '../../polls/models.dart';

abstract class PollsRepositoryInterface {
  Future<List<Poll>> getPolls({String? state, String? district, String? city, double? lat, double? lng});
  Future<Poll> getPoll(String id);
  Future<Poll> vote(String pollId, String optionId);
}
