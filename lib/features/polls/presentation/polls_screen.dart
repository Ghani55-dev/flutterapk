import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/polls_providers.dart';
import 'poll_card.dart';

class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pollsNotifierProvider);
    final notifier = ref.read(pollsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Polls')),
      body: RefreshIndicator(
        onRefresh: () async => notifier.loadPolls(),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: state.polls.length,
                itemBuilder: (context, idx) {
                  final poll = state.polls[idx];
                  return PollCard(poll: poll, onVote: (optionId) => notifier.vote(poll.id, optionId));
                },
              ),
      ),
    );
  }
}
