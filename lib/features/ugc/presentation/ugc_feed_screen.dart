import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/ugc_providers.dart';
import '../../home/presentation/widgets/shimmer.dart';
import '../data/ugc_models.dart';

class UGCFeedScreen extends ConsumerStatefulWidget {
  const UGCFeedScreen({super.key});

  @override
  ConsumerState<UGCFeedScreen> createState() => _UGCFeedScreenState();
}

class _UGCFeedScreenState extends ConsumerState<UGCFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 280) {
      ref.read(ugcProvider.notifier).loadMoreFeed();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ugcProvider);
    final notifier = ref.read(ugcProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
        actions: [
          IconButton(onPressed: () => context.push('/community'), icon: const Icon(Icons.campaign_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refreshFeed,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (state.offline && state.showingCachedData) const SliverToBoxAdapter(child: _UGCOfflineBanner()),
            if (state.feedLoading && state.feedItems.isEmpty)
              SliverList(delegate: SliverChildBuilderDelegate((context, index) => const _UGCSkeletonCard(), childCount: 5))
            else if (state.feedError != null && state.feedItems.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _UGCErrorState(message: state.feedError!, onRetry: notifier.loadFeed))
            else if (state.feedItems.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: _UGCEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _UGCFeedCard(
                    item: state.feedItems[index],
                    onReport: () => _showReportSheet(context, state.feedItems[index]),
                  ),
                  childCount: state.feedItems.length,
                ),
              ),
            if (state.feedLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportSheet(BuildContext context, UGCReportItem item) async {
    final reasonCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(ugcProvider);
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report community post', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  TextField(controller: reasonCtrl, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Reason')),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: state.reportSubmitting
                        ? null
                        : () async {
                            final ok = await ref.read(ugcProvider.notifier).reportUGC(ugcId: item.id, reason: reasonCtrl.text.trim());
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Report submitted' : 'Could not submit report')));
                          },
                    child: state.reportSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Report'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    reasonCtrl.dispose();
  }
}

class _UGCFeedCard extends StatelessWidget {
  final UGCReportItem item;
  final VoidCallback onReport;

  const _UGCFeedCard({required this.item, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.mediaUrl?.isNotEmpty == true)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: item.mediaUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: colors.surfaceVariant),
                errorWidget: (_, __, ___) => Container(color: colors.surfaceVariant, child: Icon(Icons.image_not_supported_outlined, color: colors.onSurfaceVariant)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: colors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${item.reporterName} · ${item.trustLevel}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800))),
                    IconButton(onPressed: onReport, icon: const Icon(Icons.flag_outlined), tooltip: 'Report'),
                  ],
                ),
                if (item.location?.isNotEmpty == true) Text(item.location!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(item.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(item.description, style: Theme.of(context).textTheme.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UGCOfflineBanner extends StatelessWidget {
  const _UGCOfflineBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Text('Offline Mode - Showing Saved Community Reports', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w800)),
    );
  }
}

class _UGCSkeletonCard extends StatelessWidget {
  const _UGCSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerPlaceholder(width: double.infinity, height: 180),
          SizedBox(height: 12),
          ShimmerPlaceholder(width: 180, height: 14),
          SizedBox(height: 8),
          ShimmerPlaceholder(width: double.infinity, height: 18),
          SizedBox(height: 8),
          ShimmerPlaceholder(width: double.infinity, height: 12),
        ],
      ),
    );
  }
}

class _UGCEmptyState extends StatelessWidget {
  const _UGCEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_outlined, size: 72, color: colors.primary),
            const SizedBox(height: 14),
            Text('No community reports yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Verified local reports will appear here after review.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _UGCErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _UGCErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56),
            const SizedBox(height: 12),
            Text('Unable to load community feed', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
