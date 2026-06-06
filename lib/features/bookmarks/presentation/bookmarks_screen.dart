import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/bookmarks_providers.dart';
import '../../home/presentation/widgets/article_card.dart';
import '../../home/presentation/widgets/article_card_shimmer.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    // ensure load is triggered
    Future.microtask(() => ref.read(bookmarksNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarksNotifierProvider);
    final notifier = ref.read(bookmarksNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: Builder(builder: (context) {
        if (state.loading) {
          return ListView.builder(itemCount: 6, padding: const EdgeInsets.all(12), itemBuilder: (_, __) => const ArticleCardShimmer());
        }
        if (state.items.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bookmark_add_outlined, size: 64, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), const Text('No bookmarks yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 6), const Text('Save articles to read later.'),])));

        return ListView.builder(
          itemCount: state.items.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (c, i) {
            final a = state.items[i];
            return Dismissible(
              key: ValueKey(a.id),
              direction: DismissDirection.endToStart,
              background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
              confirmDismiss: (_) async {
                final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Remove bookmark?'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Remove'))]));
                return ok ?? false;
              },
              onDismissed: (_) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await notifier.remove(a.id);
                  messenger.showSnackBar(const SnackBar(content: Text('Bookmark removed')));
                } catch (e) {
                  messenger.showSnackBar(const SnackBar(content: Text('Failed to remove bookmark')));
                }
              },
              child: ArticleCard(article: a),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(onPressed: () => notifier.load(), child: const Icon(Icons.refresh)),
    );
  }
}
