import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../polls/models.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/auth_controller.dart';

class PollCard extends StatelessWidget {
  final Poll poll;
  final void Function(String optionId) onVote;
  const PollCard({super.key, required this.poll, required this.onVote});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poll.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...poll.options.map((o) {
              final total = poll.options.fold<int>(0, (t, it) => t + it.votes);
              final percent = total == 0 ? 0.0 : o.votes / total;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: InkWell(
                  onTap: poll.isExpired || poll.userVotedOptionId != null
                      ? null
                      : () {
                          // Check auth; if guest show auth gate
                          // Using ProviderScope read is not available here, so use a workaround by looking up InheritedProvider
                          final ctx = context;
                          final container = ProviderScope.containerOf(ctx, listen: false);
                          final auth = container.read(authNotifierProvider);
                          if (auth.status != AuthStatus.authenticated) {
                            showAuthGate(ctx);
                            return;
                          }
                          onVote(o.id);
                        },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.text),
                            const SizedBox(height: 6),
                            Stack(
                              children: [
                                Container(height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                                FractionallySizedBox(widthFactor: percent, child: Container(height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(4)))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(percent * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              );
            }),
            if (poll.isExpired) Padding(padding: const EdgeInsets.only(top:8.0), child: Text('Poll closed', style: TextStyle(color: Colors.grey)))
          ],
        ),
      ),
    );
  }
}
