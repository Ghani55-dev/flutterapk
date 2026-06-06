import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../../../providers/home_providers.dart';
import '../../location/location_provider.dart';
import 'widgets/article_card.dart';
import '../../reels/models.dart';
import '../../../features/ads/presentation/widgets/ad_card.dart';
import '../../../providers/ads_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../features/ads/models.dart';
import 'widgets/article_card_shimmer.dart';
import 'widgets/featured_carousel.dart';
import 'widgets/category_chips.dart';
import '../../reels/presentation/video_preview_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../article/presentation/article_detail_screen.dart';
import '../../epaper/presentation/epaper_card.dart';
import '../../../core/utils/freshness.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollCtrl = ScrollController();
  List<AdItem> _feedAds = const [];
  bool _adsLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    Future.microtask(_loadFeedAds);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(feedNotifierProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedNotifierProvider);
    final notifier = ref.read(feedNotifierProvider.notifier);
    final feedList = _buildItemList(state.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VARADHI'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(onPressed: () => context.push('/location-picker'), icon: const Icon(Icons.location_on_outlined)),
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(notificationUnreadCountProvider).valueOrNull ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none)),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          unread > 9 ? '9+' : unread.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onError, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await notifier.refresh();
          await _loadFeedAds();
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.offline && state.showingCachedData) const _OfflineFeedBanner(),
                  _buildLiveUpdates(state),
                  _buildFeatured(state),
                  _buildCategoryBar(),
                  _buildQuote(state),
                  _buildHorizontalArticles('Trending / Breaking', _trendingArticles(state)),
                  _buildVideoStrip('Short reels', state.shortsPreviews, openReels: true),
                  _buildLiveStrip(state),
                  _buildCmsBlocks(state),
                  _buildVideoStrip('Video previews', state.videoPreviews),
                  _buildEpaperStrip(state),
                  _buildHorizontalArticles('Recommended', state.recommendations),
                  _buildTtsBanner(state),
                  _sectionTitle('Latest news'),
                ],
              ),
                ),
            if (state.isLoading && state.items.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ArticleCardShimmer(),
                  childCount: 6,
                ),
              )
            else if (state.items.isEmpty && !_hasAnyHomeContent(state) && state.error == null)
              SliverToBoxAdapter(
                child: _AuthenticatedEmptyState(
                  onRefresh: () async {
                    await notifier.refresh();
                    await _loadFeedAds();
                  },
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = feedList[index];
                    if (item is AdItem) return AdCard(ad: item);
                    return ArticleCard(article: item as Article);
                  },
                  childCount: feedList.length,
                ),
              ),
            SliverToBoxAdapter(child: _buildFooter(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(child: Text('VARADHI', style: Theme.of(context).textTheme.headlineSmall)),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => context.push('/')),
            ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () => context.push('/profile')),
            ListTile(leading: const Icon(Icons.bookmark), title: const Text('Bookmarks'), onTap: () => context.push('/bookmarks')),
            ListTile(leading: const Icon(Icons.campaign_outlined), title: const Text('Community Reporter'), onTap: () => context.push('/community')),
            ListTile(leading: const Icon(Icons.location_on), title: const Text('Set location'), onTap: () => context.push('/location-picker')),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () => context.push('/settings')),
            const Spacer(),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'), onTap: () => context.push('/about')),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatured(dynamic state) {
    if (state.featured.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: FeaturedCarousel(items: state.featured));
  }

  Widget _buildCategoryBar() {
    return const Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: CategoryChips(),
    );
  }

  List<dynamic> _buildItemList(List<Article> articles) {
    final sortedArticles = List<Article>.from(articles)
      ..sort((a, b) {
        final pa = a.publishedAt;
        final pb = b.publishedAt;
        final paPri = freshnessPriority(pa);
        final pbPri = freshnessPriority(pb);
        if (paPri != pbPri) return paPri.compareTo(pbPri);
        if (pa == null && pb == null) return 0;
        if (pa == null) return 1;
        if (pb == null) return -1;
        return pb.compareTo(pa);
      });
    if (_feedAds.isEmpty) return sortedArticles;

    final combined = <dynamic>[];
    var articleIndex = 0;
    var adIndex = 0;
    for (final article in sortedArticles) {
      combined.add(article);
      articleIndex += 1;
      final ad = _feedAds[adIndex % _feedAds.length];
      final frequency = ad.displayFrequency > 0 ? ad.displayFrequency : 5;
      if (articleIndex % frequency == 0) {
        combined.add(ad);
        adIndex += 1;
      }
    }
    return combined;
  }

  Future<void> _loadFeedAds() async {
    if (_adsLoading) return;
    _adsLoading = true;
    try {
      final locAv = ref.read(locationProvider);
      Map<String, String>? loc;
      if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      final ads = await ref.read(adsRepositoryProvider).fetchAds(zone: 'feed', state: loc?['state'], district: loc?['district'], city: loc?['city']);
      if (mounted) setState(() => _feedAds = ads);
    } catch (_) {
      if (mounted) setState(() => _feedAds = const []);
    } finally {
      _adsLoading = false;
    }
  }

  Widget _buildFooter(dynamic state) {
    if (state.isLoading) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    if (state.error != null) return Padding(padding: const EdgeInsets.all(16), child: Center(child: Text('Error: ${state.error}')));
    return const SizedBox(height: 48);
  }

  bool _hasAnyHomeContent(dynamic state) {
    return state.featured.isNotEmpty ||
        state.liveNews.isNotEmpty ||
        state.videoPreviews.isNotEmpty ||
        state.shortsPreviews.isNotEmpty ||
        state.epapers.isNotEmpty ||
        state.recommendations.isNotEmpty ||
        state.cmsBlocks.isNotEmpty ||
        state.quote != null;
  }

  List<Article> _trendingArticles(dynamic state) {
    final all = <Article>[...state.featured, ...state.items, ...state.recommendations];
    final seen = <String>{};
    return all.where((a) => a.title.isNotEmpty && seen.add(a.id)).take(10).toList();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildLiveUpdates(dynamic state) {
    final liveTitle = state.liveNews.isNotEmpty ? (state.liveNews.first['title']?.toString() ?? 'Live updates') : 'Live updates';
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.error.withOpacity(0.25))),
      child: Row(children: [
        Icon(Icons.circle, color: colors.error, size: 10),
        const SizedBox(width: 8),
        Expanded(child: Text(liveTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: colors.onErrorContainer))),
        Text('${state.liveNews.length} live', style: Theme.of(context).textTheme.labelSmall),
      ]),
    );
  }

  Widget _buildQuote(dynamic state) {
    final quote = state.quote;
    if (quote == null) return const SizedBox.shrink();
    final text = quote['text']?.toString() ?? quote['quote']?.toString() ?? quote['content']?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final author = quote['author']?.toString() ?? quote['source']?.toString();
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: colors.onTertiaryContainer)),
        if (author != null && author.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(author, style: Theme.of(context).textTheme.labelMedium)),
      ]),
    );
  }

  Widget _buildHorizontalArticles(String title, List<Article> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    // sort by freshness
    final sorted = List<Article>.from(items);
    sorted.sort((a, b) {
      final paPri = freshnessPriority(a.publishedAt);
      final pbPri = freshnessPriority(b.publishedAt);
      if (paPri != pbPri) return paPri.compareTo(pbPri);
      if (a.publishedAt == null && b.publishedAt == null) return 0;
      if (a.publishedAt == null) return 1;
      if (b.publishedAt == null) return -1;
      return b.publishedAt!.compareTo(a.publishedAt!);
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(title),
      SizedBox(
        height: 156,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final a = sorted[i];
            return SizedBox(
              width: 220,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: a.slug))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.categoryName ?? 'News', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (a.excerpt != null) Text(a.excerpt!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildVideoStrip(String title, List<dynamic> items, {bool openReels = false}) {
    if (items.isEmpty) return const SizedBox.shrink();
    // sort video items by freshness if publishedAt available
    final sorted = List<dynamic>.from(items);
    try {
      sorted.sort((a, b) {
        DateTime? pa;
        DateTime? pb;
        if (a is VideoItem) pa = a.publishedAt;
        if (b is VideoItem) pb = b.publishedAt;
        final paPri = freshnessPriority(pa);
        final pbPri = freshnessPriority(pb);
        if (paPri != pbPri) return paPri.compareTo(pbPri);
        if (pa == null && pb == null) return 0;
        if (pa == null) return 1;
        if (pb == null) return -1;
        return pb.compareTo(pa);
      });
    } catch (_) {}
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(title),
      SizedBox(
        height: 150,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final v = sorted[i] as dynamic;
            final String resolvedThumb = (v.thumbnail != null && v.thumbnail!.isNotEmpty)
                ? v.thumbnail!
                : ((v.youtubeVideoId != null && v.youtubeVideoId!.isNotEmpty)
                    ? 'https://img.youtube.com/vi/${v.youtubeVideoId}/hqdefault.jpg'
                    : '');
            if (kDebugMode) {
              debugPrint('[LIVE THUMBNAIL] $resolvedThumb');
            }

            return InkWell(
              onTap: openReels
                  ? () => context.go('/reels')
                  : () {
                      if (kDebugMode) {
                        debugPrint('[VIDEO PREVIEW CLICK]');
                        debugPrint('[VIDEO URL] ${v.url}');
                        debugPrint('[PLAYER TYPE] ${v.isYouTube ? 'YoutubePlayer' : 'VideoPlayer'}');
                      }
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPreviewPlayer(url: v.url ?? '', isYouTube: v.isYouTube ?? false, youtubeVideoId: v.youtubeVideoId)));
                    },
              child: SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(fit: StackFit.expand, children: [
                    if (resolvedThumb.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: resolvedThumb,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.black12),
                        errorWidget: (_, __, ___) => Container(color: Colors.black12),
                      )
                    else
                      Container(color: Colors.black12),
                    const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36)),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4)])),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildLiveStrip(dynamic state) {
    final raw = state.liveNews as List<dynamic>?;
    if (raw == null || raw.isEmpty) {
      // graceful empty state
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [Icon(Icons.live_tv, color: colors.error), const SizedBox(width: 8), Expanded(child: Text('No live broadcasts currently', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onErrorContainer)))]),
        ),
      );
    }

    // normalize items and support many backend shapes
    final normalized = raw.map((it) {
      final m = it is Map ? Map<String, dynamic>.from(it) : <String, dynamic>{};
      final title = (m['title'] ?? m['headline'] ?? m['name'])?.toString() ?? '';
      final channel = (m['channel_name'] ?? m['source'] ?? m['provider'])?.toString() ?? '';
      String thumb = (m['thumbnail_url'] ?? m['thumbnail'] ?? m['image'])?.toString() ?? '';
      String? youtubeId = (m['youtube_video_id'] ?? m['youtube_id'])?.toString();
      String? youtubeUrl = (m['youtube_url'] ?? m['youtube'] ?? m['video_url'])?.toString();
      String? mediaUrl = (m['media_url'] ?? m['video_url'] ?? m['url'])?.toString();
      final publishedAt = m['published_at'] ?? m['publishedAt'] ?? m['pub_date'];
      DateTime? published;
      try {
        if (publishedAt != null) published = DateTime.tryParse(publishedAt.toString());
      } catch (_) {}

      // if youtubeId missing, try extract from youtubeUrl
      if ((youtubeId == null || youtubeId.isEmpty) && youtubeUrl != null && youtubeUrl.isNotEmpty) {
        try {
          youtubeId = YoutubePlayer.convertUrlToId(youtubeUrl);
        } catch (_) {}
      }

      // thumbnail fallback to youtube thumbnail if available
      if ((thumb.isEmpty) && youtubeId != null && youtubeId.isNotEmpty) {
        thumb = 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
      }

      final isYouTube = (youtubeId != null && youtubeId.isNotEmpty) || (youtubeUrl != null && youtubeUrl.contains('youtube'));
      final playable = isYouTube ? (youtubeUrl ?? '') : (mediaUrl ?? '');
      return {
        'title': title,
        'channel': channel,
        'thumb': thumb,
        'youtubeId': youtubeId,
        'youtubeUrl': youtubeUrl,
        'mediaUrl': mediaUrl,
        'isYouTube': isYouTube,
        'published': published,
        'raw': m,
      };
    }).toList();

    // sort by freshness (today -> older) and pick top 5
    normalized.sort((a, b) {
      final pa = a['published'] as DateTime?;
      final pb = b['published'] as DateTime?;
      final paPri = freshnessPriority(pa);
      final pbPri = freshnessPriority(pb);
      if (paPri != pbPri) return paPri.compareTo(pbPri);
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pb.compareTo(pa);
    });

    final items = normalized.take(5).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Live news'),
      SizedBox(
        height: 120,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final item = Map<String, dynamic>.from(items[i]);
            final title = item['title'] as String? ?? '';
            final channel = item['channel'] as String? ?? '';
            final resolvedThumb = item['thumb'] as String? ?? '';
            final youtubeId = item['youtubeId'] as String?;
            final youtubeUrl = item['youtubeUrl'] as String?;
            final mediaUrl = item['mediaUrl'] as String?;
            final isYouTube = item['isYouTube'] as bool? ?? false;
            final pd = item['published'] as DateTime?;

            return InkWell(
              onTap: () {
                if (kDebugMode) {
                  debugPrint('[LIVE CLICK] title=$title channel=$channel');
                  debugPrint('[LIVE URL] youtubeId=$youtubeId youtubeUrl=$youtubeUrl mediaUrl=$mediaUrl');
                }

                String playerType = 'unknown';
                if (isYouTube) playerType = 'YoutubePlayer';
                else if (mediaUrl != null && mediaUrl.isNotEmpty) playerType = 'VideoPlayer';
                if (kDebugMode) debugPrint('[LIVE PLAYER TYPE] $playerType');
                // Navigation to unified player used by reels
                if (isYouTube) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPreviewPlayer(url: youtubeUrl ?? '', isYouTube: true, youtubeVideoId: youtubeId)));
                } else if (mediaUrl != null && mediaUrl.isNotEmpty) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPreviewPlayer(url: mediaUrl, isYouTube: false, youtubeVideoId: null)));
                } else {
                  // nothing playable, show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No playable stream available')));
                }
              },
              child: SizedBox(
                width: 220,
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Stack(children: [
                    Positioned.fill(
                      child: resolvedThumb.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: resolvedThumb,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.black12, child: const Icon(Icons.live_tv, size: 48, color: Colors.black38)),
                              errorWidget: (_, __, ___) => Container(color: Colors.black12, child: const Icon(Icons.live_tv, size: 48, color: Colors.black38)),
                            )
                          : Container(color: Colors.black12, child: const Icon(Icons.live_tv, size: 48, color: Colors.black38)),
                    ),
                    Positioned.fill(child: Container(color: Colors.black26)),
                    Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                    Center(child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.95), size: 52)),
                    // freshness badge
                    if (pd != null)
                      Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Text(formatFreshnessTag(pd), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                    Positioned(left: 12, right: 12, bottom: 12, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), if (channel.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(channel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)))])),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildCmsBlocks(dynamic state) {
    if (state.cmsBlocks.isEmpty) {
      // graceful placeholder when no CMS blocks available
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: const Text('No updates right now')),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Updates'),
      ...state.cmsBlocks.take(2).map<Widget>((item) {
        final title = item['title']?.toString() ?? item['slug']?.toString() ?? 'CMS';
        final body = item['summary']?.toString() ?? item['content']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Card(child: ListTile(title: Text(title), subtitle: body.isEmpty ? null : Text(body, maxLines: 2, overflow: TextOverflow.ellipsis))),
        );
      }),
    ]);
  }

  Widget _buildEpaperStrip(dynamic state) {
    if (state.epapers.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Epaper'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Card(child: ListTile(title: const Text('No Epapers available'), trailing: ElevatedButton(onPressed: () => ref.read(feedNotifierProvider.notifier).loadHomeModules(), child: const Text('Refresh'))))),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Epaper'),
      SizedBox(
        height: 112,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: state.epapers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final e = state.epapers[i];
            return SizedBox(
              width: 180,
              child: EpaperCard(
                epaper: e,
                onTap: () {
                  try {
                    if (kDebugMode) debugPrint('[EPAPER NAV] HOME -> LANDING id=${e.id} title=${e.title}');
                    if (kDebugMode) debugPrint('[PDF URL] ${e.pdfUrl}');
                  } catch (_) {}
                  context.push('/epapers/${e.id}');
                },
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildTtsBanner(dynamic state) {
    if (!state.ttsAvailable) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(8)),
      child: const Row(children: [Icon(Icons.volume_up_outlined), SizedBox(width: 10), Expanded(child: Text('Text-to-speech is available on article pages'))]),
    );
  }
}

class _OfflineFeedBanner extends StatelessWidget {
  const _OfflineFeedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.secondary.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: colors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline Mode - Showing Saved News',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthenticatedEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _AuthenticatedEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.newspaper_rounded, size: 42, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 18),
          Text('No news available', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Your personalized VARADHI feed is empty right now. Pull to refresh or check back shortly.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
