import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../../../providers/home_providers.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedNotifierProvider);
    final notifier = ref.read(feedNotifierProvider.notifier);

    if (state.categories.isEmpty) {
      // shimmer placeholder
      return SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) => Container(width: 80, height: 32, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20))),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: 6,
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final CategoryModel c = state.categories[index];
          final key = c.slug?.isNotEmpty == true ? c.slug! : c.id;
          final selected = state.selectedCategoryId == key;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: ChoiceChip(
              label: Text(c.name),
              selected: selected,
              onSelected: (_) => notifier.setCategory(key),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(color: selected ? Colors.white : null),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: state.categories.length,
      ),
    );
  }
}
