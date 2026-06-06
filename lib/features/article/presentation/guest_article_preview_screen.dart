import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/article_providers.dart';
import '../data/models.dart';

class GuestArticlePreviewScreen extends ConsumerStatefulWidget {
  final String slug;

  const GuestArticlePreviewScreen({super.key, required this.slug});

  @override
  ConsumerState<GuestArticlePreviewScreen> createState() => _GuestArticlePreviewScreenState();
}

class _GuestArticlePreviewScreenState extends ConsumerState<GuestArticlePreviewScreen> {
  final _scrollController = ScrollController();
  ArticleDetail? _article;
  List<ArticleDetail> _related = const [];
  bool _loading = true;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    final repository = ref.read(articleRepositoryProvider);
    try {
      final article = await repository.getDetail(widget.slug, cacheFirst: false);
      final related = await repository.getRelated(article.categorySlug);
      if (!mounted) return;
      setState(() {
        _article = article;
        _related = related.where((item) => item.slug != article.slug).take(5).toList();
        _loading = false;
      });
    } catch (error) {
      final cached = _isNetworkError(error) ? await repository.getCachedDetail(widget.slug) : null;
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _article = cached;
          _related = const [];
          _offline = true;
          _loading = false;
        });
        return;
      }

      setState(() {
        _error = _isNetworkError(error)
            ? 'You appear to be offline. Pull to refresh when the connection returns.'
            : error.toString();
        _offline = _isNetworkError(error);
        _loading = false;
      });
    }
  }

  bool _isNetworkError(Object error) {
    if (error is! DioException) return false;
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(onPressed: () => _showUnlockSheet(context), icon: const Icon(Icons.bookmark_border_rounded)),
          IconButton(onPressed: () => _showUnlockSheet(context), icon: const Icon(Icons.share_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const _GuestArticleSkeleton()
            : _error != null
                ? _GuestArticleError(message: _error!, onRetry: _load)
                : _article == null
                    ? _GuestArticleEmpty(onRetry: _load)
                    : _PreviewContent(
                        scrollController: _scrollController,
                        article: _article!,
                        related: _related,
                        offline: _offline,
                        onRestricted: () => _showUnlockSheet(context),
                      ),
      ),
    );
  }

  static void _showUnlockSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Unlock Full VARADHI Experience',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            const _Benefit(text: 'Unlimited News'),
            const _Benefit(text: 'Personalized Feed'),
            const _Benefit(text: 'Live Alerts'),
            const _Benefit(text: 'Bookmark Stories'),
            const _Benefit(text: 'Poll Participation'),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => context.go('/login'), child: const Text('Login')),
            OutlinedButton(onPressed: () => context.go('/register'), child: const Text('Register')),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later')),
          ],
        ),
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  final ScrollController scrollController;
  final ArticleDetail article;
  final List<ArticleDetail> related;
  final bool offline;
  final VoidCallback onRestricted;

  const _PreviewContent({
    required this.scrollController,
    required this.article,
    required this.related,
    required this.offline,
    required this.onRestricted,
  });

  @override
  Widget build(BuildContext context) {
    final preview = _previewText(article.content ?? article.summary ?? '');

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (offline) const SliverToBoxAdapter(child: _OfflineBanner()),
        SliverToBoxAdapter(child: _HeroImage(article: article)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(text: article.categorySlug ?? 'News'),
                    if (article.readTimeMinutes != null) _MetaChip(text: '${article.readTimeMinutes} min read'),
                    const _MetaChip(text: 'Local'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(article.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(article.authorName ?? article.sourceName ?? 'VARADHI Desk')),
                    if (article.publishedAt != null)
                      Text(article.publishedAt!.toLocal().toString().split(' ').first,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                if (article.summary != null && article.summary!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(article.summary!, style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.35)),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Text(preview, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65)),
          ),
        ),
        SliverToBoxAdapter(child: _ContinueReadingCard(onRestricted: onRestricted)),
        if (related.isNotEmpty) SliverToBoxAdapter(child: _RelatedStories(items: related)),
        SliverToBoxAdapter(child: const SizedBox(height: 32)),
      ],
    );
  }

  String _previewText(String raw) {
    final text = raw.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 480) return article.summary ?? text;

    final ratio = text.length >= 2400 ? 0.22 : 0.25;
    final minLimit = (text.length * 0.20).round();
    final maxLimit = (text.length * 0.30).round();
    final limit = (text.length * ratio).round().clamp(minLimit, maxLimit);
    return '${text.substring(0, limit).trim()}...';
  }
}

class _HeroImage extends StatelessWidget {
  final ArticleDetail article;

  const _HeroImage({required this.article});

  @override
  Widget build(BuildContext context) {
    if (article.thumbnailUrl == null || article.thumbnailUrl!.isEmpty) {
      return Container(
        height: 220,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.newspaper_rounded, size: 52)),
      );
    }

    return SizedBox(
      height: 240,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: article.thumbnailUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 900,
        placeholder: (_, __) => const _ShimmerBox(),
        errorWidget: (_, __, ___) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image_rounded, size: 44)),
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  final VoidCallback onRestricted;

  const _ContinueReadingCard({required this.onRestricted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF151A24), Color(0xFF2B1A22)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Continue Reading',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Unlock Full VARADHI Experience', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _Benefit(text: 'Unlimited News', dark: true),
          const _Benefit(text: 'Personalized Feed', dark: true),
          const _Benefit(text: 'Live Alerts', dark: true),
          const _Benefit(text: 'Bookmark Stories', dark: true),
          const _Benefit(text: 'Poll Participation', dark: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: () => context.go('/login'), child: const Text('Login'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => context.go('/register'), child: const Text('Register'))),
            ],
          ),
          TextButton(onPressed: onRestricted, child: const Text('Later')),
        ],
      ),
    );
  }
}

class _RelatedStories extends StatelessWidget {
  final List<ArticleDetail> items;

  const _RelatedStories({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Text('Related Stories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => context.go('/guest-article/${item.slug}'),
                child: SizedBox(
                  width: 230,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(70)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetaChip(text: item.categorySlug ?? 'News'),
                          const Spacer(),
                          Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          const Text('Read preview', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;

  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  final bool dark;

  const _Benefit({required this.text, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFC857), size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: dark ? Colors.white : null, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GuestArticleSkeleton extends StatelessWidget {
  const _GuestArticleSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _ShimmerBox(height: 240),
        Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 92, height: 24, borderRadius: 10),
              SizedBox(height: 14),
              _ShimmerBox(height: 24, borderRadius: 10),
              SizedBox(height: 10),
              _ShimmerBox(width: 260, height: 24, borderRadius: 10),
              SizedBox(height: 18),
              _ShimmerBox(height: 16, borderRadius: 8),
              SizedBox(height: 10),
              _ShimmerBox(height: 16, borderRadius: 8),
              SizedBox(height: 10),
              _ShimmerBox(width: 220, height: 16, borderRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const _ShimmerBox({this.width, this.height, this.borderRadius = 0});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface.withAlpha(180);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1 + (_controller.value * 2), -0.3),
            end: Alignment(_controller.value * 2, 0.3),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}

class _GuestArticleEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _GuestArticleEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.article_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 18),
        Text('Article unavailable', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('This story may have moved or is no longer available.', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ],
    );
  }
}

class _GuestArticleError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GuestArticleError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline_rounded, size: 68, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 18),
        Text('Could not load preview', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Offline Mode - Showing Saved Preview',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
