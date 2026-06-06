import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/polls_repository_interface.dart';
import '../location/location_provider.dart';
import 'models.dart';
import '../../core/storage/secure_storage_interface.dart';

class PollsState {
  final bool loading;
  final List<Poll> polls;
  final String? error;

  PollsState({this.loading = false, this.polls = const [], this.error});

  PollsState copyWith({bool? loading, List<Poll>? polls, String? error}) =>
      PollsState(loading: loading ?? this.loading, polls: polls ?? this.polls, error: error ?? this.error);
}

class PollsNotifier extends StateNotifier<PollsState> {
  final PollsRepositoryInterface repository;
  final SecureStorageInterface storage;
  final Ref? ref;
  PollsNotifier({this.ref, required this.repository, required this.storage}) : super(PollsState());

  Future<void> loadPolls() async {
    state = state.copyWith(loading: true, error: null);
    try {
      Map<String, String>? loc;
      if (ref != null) {
        final locAv = ref!.read(locationProvider);
        if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      }
      final polls = await repository.getPolls(state: loc?['state'], district: loc?['district'], city: loc?['city']);
      state = state.copyWith(loading: false, polls: polls);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> vote(String pollId, String optionId) async {
    final alreadyVoted = await storage.read('voted_$pollId');
    if (alreadyVoted != null) return;

    // optimistic update
    final idx = state.polls.indexWhere((p) => p.id == pollId);
    if (idx == -1) return;
    final poll = state.polls[idx];
    final updated = poll.copyWithIncrement(optionId);
    final newList = List<Poll>.from(state.polls)..[idx] = updated;
    state = state.copyWith(polls: newList);

    try {
      final refreshed = await repository.vote(pollId, optionId);
      final finalPoll = refreshed.userVotedOptionId != null ? refreshed : refreshed.copyWith(userVotedOptionId: optionId);
      final newList2 = List<Poll>.from(state.polls);
      newList2[idx] = finalPoll;
      state = state.copyWith(polls: newList2);
      await storage.write('voted_$pollId', optionId);
    } catch (e) {
      // rollback
      final newList2 = List<Poll>.from(state.polls)..[idx] = poll;
      state = state.copyWith(polls: newList2);
    }
  }
}
