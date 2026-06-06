import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/search_providers.dart';

class RecentSearches extends ConsumerWidget {
  const RecentSearches({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchNotifierProvider);
    final notifier = ref.read(searchNotifierProvider.notifier);
    final history = state.history;
    if (history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent searches', style: Theme.of(context).textTheme.titleSmall),
              TextButton(onPressed: () => notifier.clearHistory(), child: const Text('Clear')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: history.map<Widget>((h) {
              return InputChip(
                label: Text(h),
                onPressed: () => notifier.setQuery(h),
                onDeleted: () => notifier.removeHistoryItem(h),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
