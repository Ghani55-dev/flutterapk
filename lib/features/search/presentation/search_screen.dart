import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/widgets/article_card_shimmer.dart';
import '../../../providers/search_providers.dart';
import 'widgets/recent_searches.dart';
import 'widgets/search_result_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final notifier = ref.read(searchNotifierProvider.notifier);
    final query = state.query;
    _controller.text = query;
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              onChanged: (v) => notifier.setQuery(v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search for news, topics, authors',
                suffixIcon: query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _controller.clear(); notifier.clearQuery(); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: (_) {
              if (query.isEmpty) {
                return ListView(
                  children: const [RecentSearches()],
                );
              }
              final items = state.items;
              final isLoading = state.isLoading;
              if (isLoading && items.isEmpty) return const ArticleCardShimmer();
              if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 48), const SizedBox(height: 8), const Text('No results')],));
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification && n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    notifier.fetchNextPage();
                  }
                  return false;
                },
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = items[i];
                    return SearchResultCard(article: a);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
