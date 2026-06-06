import 'package:flutter_test/flutter_test.dart';
import 'package:incite_flutter/features/polls/data/polls_repository_interface.dart';
import 'package:incite_flutter/features/polls/polls_notifier.dart';
import 'package:incite_flutter/features/polls/models.dart';
import 'package:incite_flutter/core/storage/secure_storage_interface.dart';

class _FakeRepo implements PollsRepositoryInterface {
  bool shouldFail = false;

  @override
  Future<List<Poll>> getPolls({String? state, String? district, String? city, double? lat, double? lng}) async => [];

  @override
  Future<Poll> getPoll(String id) async => throw UnimplementedError();

  @override
  Future<Poll> vote(String pollId, String optionId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldFail) throw Exception('vote failed');
    return Poll(id: pollId, question: 'q', options: [PollOption(id: optionId, text: 'o', votes: 5)]);
  }
}

class InMemoryStorage implements SecureStorageInterface {
  final Map<String, String> _m = {};
  @override
  Future<void> write(String key, String value) async => _m[key] = value;

  @override
  Future<String?> read(String key) async => _m[key];

  @override
  Future<void> delete(String key) async {
    _m.remove(key);
  }
}

void main() {
  test('optimistic vote succeeds and persists', () async {
    final repo = _FakeRepo();
    final storage = InMemoryStorage();
    final notifier = PollsNotifier(repository: repo, storage: storage);
    final p = Poll(id: 'p1', question: 'Q', options: [PollOption(id: 'o1', text: 'A', votes: 1)]);
    notifier.state = notifier.state.copyWith(polls: [p]);

    await notifier.vote('p1', 'o1');

    expect(notifier.state.polls.first.userVotedOptionId, 'o1');
    expect(await storage.read('voted_p1'), 'o1');
  });

  test('optimistic vote rolls back on failure', () async {
    final repo = _FakeRepo()..shouldFail = true;
    final storage = InMemoryStorage();
    final notifier = PollsNotifier(repository: repo, storage: storage);
    final p = Poll(id: 'p2', question: 'Q', options: [PollOption(id: 'o1', text: 'A', votes: 2)]);
    notifier.state = notifier.state.copyWith(polls: [p]);

    await notifier.vote('p2', 'o1');

    expect(notifier.state.polls.first.userVotedOptionId, isNot('o1'));
    expect(await storage.read('voted_p2'), isNull);
  });
}
