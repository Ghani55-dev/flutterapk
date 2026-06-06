import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/widgets/article_card_shimmer.dart';
import '../../home/presentation/widgets/shimmer.dart';
import '../../../providers/article_providers.dart';
import '../../home/data/models.dart';
import '../../../providers/history_providers.dart';
import '../../tts/tts_providers.dart';
import '../../tts/presentation/tts_mini_player.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/auth_controller.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();

  double _progress = 0.0;
  late final AnimationController _bmController;
  late final Animation<double> _bmScale;

  @override
  void initState() {
    super.initState();
    _bmController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _bmScale = Tween<double>(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _bmController, curve: Curves.easeOutBack));
    _scrollCtrl.addListener(() {
      final max = _scrollCtrl.position.maxScrollExtent > 0 ? _scrollCtrl.position.maxScrollExtent : 1.0;
      setState(() {
        _progress = (_scrollCtrl.position.pixels / max).clamp(0.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _bmController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articleNotifierProvider(widget.slug));
    final notifier = ref.read(articleNotifierProvider(widget.slug).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              final auth = ref.read(authNotifierProvider);
              if (auth.status != AuthStatus.authenticated) {
                if (!mounted) return;
                await showAuthGate(context);
                return;
              }
              // trigger pulse
              try {
                await _bmController.forward();
                await _bmController.reverse();
              } catch (_) {}
              await notifier.toggleBookmark();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ScaleTransition(
                scale: _bmScale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: state.article?.isBookmarked == true
                      ? const Icon(Icons.bookmark, key: ValueKey('bm'))
                      : const Icon(Icons.bookmark_border, key: ValueKey('bm2')),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.headset),
            onPressed: () async {
              final a = state.article;
              if (a == null) return;
              final content = a.content ?? a.summary ?? a.title;
              // request TTS generation
              await ref.read(ttsNotifierProvider.notifier).requestTts(content: content, language: 'en', objectType: 'article', objectId: a.id?.toString() ?? a.slug);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final a = state.article;
              if (a == null) return;
              final url = 'https://incite-backend.onrender.com/articles/${a.slug}/';
              final text = '${a.title}\n\n${a.summary ?? ''}\n\n$url';
              Share.share(text, subject: a.title);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (state.isLoading && state.article == null)
            ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: 6,
              itemBuilder: (_, i) => const ArticleCardShimmer(),
            )
          else if (state.error != null)
            Center(child: Text('Error: ${state.error}'))
          else if (state.article != null)
            _articleWithHistory(state, notifier)
          else
            const Center(child: Text('No article')),
          Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(value: _progress, minHeight: 3)),
        ],
      ),
      bottomNavigationBar: const TtsMiniPlayer(),
    );
  }

  Widget _buildContent(dynamic state, dynamic notifier) {
    final a = state.article!;
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.thumbnailUrl != null)
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Hero(
                    tag: 'article-${a.slug}',
                    child: CachedNetworkImage(
                      imageUrl: a.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
                      errorWidget: (_, __, ___) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (a.authorName != null) Text(a.authorName!, style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    if (a.publishedAt != null) Text(a.publishedAt!.toLocal().toString().split(' ').first, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 12),
                  if (a.summary != null) Text(a.summary!, style: Theme.of(context).textTheme.titleMedium),
                ]),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: a.content != null && a.content!.isNotEmpty
                ? Html(
                    data: a.content!,
                    style: {
                      'body': Style(fontSize: FontSize(16.0), lineHeight: const LineHeight(1.6)),
                      'p': Style(margin: Margins.symmetric(vertical: 8)),
                      'img': Style(margin: Margins.symmetric(vertical: 8)),
                    },
                  )
                : _renderBody(a.content ?? ''),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 20)),
        if ((state.related ?? []).isNotEmpty)
          SliverToBoxAdapter(child: _buildRelated(state.related)),
        SliverToBoxAdapter(child: const SizedBox(height: 80)),
      ],
    );
  }

  Widget _renderBody(String html) {
    // simple HTML tag stripper for now; can replace with flutter_html later
    final text = html.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return Text(text, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.left);
  }

  Widget _buildRelated(List related) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text('Related', style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final item = related[index];
              return SizedBox(
                width: 280,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: item.slug))),
                  child: Card(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      if (item.thumbnailUrl != null)
                        CachedNetworkImage(
                          imageUrl: item.thumbnailUrl!,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerPlaceholder(width: double.infinity, height: 90),
                          errorWidget: (_, __, ___) => const ShimmerPlaceholder(width: double.infinity, height: 90),
                        )
                      else
                        const ShimmerPlaceholder(width: double.infinity, height: 90),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: related.length,
          ),
        ),
      ],
    );
  }

  Widget _articleWithHistory(dynamic state, dynamic notifier) {
    // schedule history write and return the content widget
    Future.microtask(() async {
      try {
        final a = state.article;
        final art = Article(id: a.id?.toString() ?? a.slug, slug: a.slug, title: a.title, excerpt: a.summary, imageUrl: a.thumbnailUrl, publishedAt: a.publishedAt);
        await ref.read(historyRepositoryProvider).add(art);
        ref.invalidate(historyNotifierProvider);
      } catch (_) {}
    });
    return _buildContent(state, notifier);
  }
}
