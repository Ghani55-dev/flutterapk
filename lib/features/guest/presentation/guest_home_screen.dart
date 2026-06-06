import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../providers/ads_providers.dart';
import '../../ads/models.dart';
import '../../article/presentation/article_detail_screen.dart';
import '../../auth/auth_controller.dart';
import '../../home/data/models.dart';
import '../../location/location_provider.dart';
import '../../reels/models.dart';
import '../guest_home_notifier.dart';

class GuestHomeScreen extends ConsumerWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guestHomeNotifierProvider);
    final location = ref.watch(locationProvider);
    final locText =
        location is AsyncData<Map<String, String>?> && location.value != null
        ? (location.value!['village'] ??
              location.value!['city'] ??
              location.value!['district'] ??
              'Local')
        : 'Choose area';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(guestHomeNotifierProvider.notifier)
              .load(categoryId: state.selectedCategoryId),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(location: locText)),
              if (state.offline && state.showingCachedData)
                const SliverToBoxAdapter(child: _OfflineBanner()),
              SliverToBoxAdapter(
                child: _BreakingStrip(
                  onRestricted: () => _showUnlockSheet(context),
                ),
              ),
              SliverToBoxAdapter(child: _CategoryChips(state: state)),
              if (state.loading && state.articles.isEmpty)
                const SliverToBoxAdapter(child: _GuestLoading())
              else if (state.error != null)
                SliverToBoxAdapter(child: _ErrorPanel(message: state.error!))
              else if (state.articles.isEmpty &&
                  state.featured.isEmpty &&
                  state.videos.isEmpty)
                SliverToBoxAdapter(
                  child: _GuestEmptyState(
                    onRefresh: () => ref
                        .read(guestHomeNotifierProvider.notifier)
                        .load(categoryId: state.selectedCategoryId),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _FeaturedCarousel(items: state.featured),
                ),
                SliverToBoxAdapter(
                  child: _TrendingStories(items: state.trending),
                ),
                SliverToBoxAdapter(
                  child: _VideoStrip(
                    items: state.videos,
                    onRestricted: () => _showUnlockSheet(context),
                  ),
                ),
                const SliverToBoxAdapter(child: UnlockVaradhiCard()),
                SliverToBoxAdapter(child: _SponsoredBand(ads: state.ads)),
                SliverToBoxAdapter(
                  child: _SectionTitle(title: 'Read previews'),
                ),
                SliverList.builder(
                  itemCount: state.articles.length,
                  itemBuilder: (context, index) {
                    final ad = state.ads.isEmpty
                        ? null
                        : state.ads[index % state.ads.length];
                    return Column(
                      children: [
                        _PreviewArticleCard(
                          article: state.articles[index],
                          onRestricted: () => _showUnlockSheet(context),
                        ),
                        if (index == 2) const _GoogleAdPlaceholder(),
                        if (index == 4 && ad != null)
                          _SponsoredArticleCard(ad: ad),
                      ],
                    );
                  },
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
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
            Text(
              'Unlock Full VARADHI Experience',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            const _UnlockFeature(
              icon: Icons.all_inclusive_rounded,
              text: 'Unlimited News',
            ),
            const _UnlockFeature(
              icon: Icons.bookmark_rounded,
              text: 'Bookmarks',
            ),
            const _UnlockFeature(
              icon: Icons.notifications_active_rounded,
              text: 'Live Alerts',
            ),
            const _UnlockFeature(
              icon: Icons.how_to_vote_rounded,
              text: 'Poll Participation',
            ),
            const _UnlockFeature(
              icon: Icons.campaign_rounded,
              text: 'Community Reporting',
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/register'),
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String location;

  const _Header({required this.location});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD166), Color(0xFFB51724)],
              ),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.appName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Guest edition',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.location_on_outlined, size: 16),
            label: Text(location, overflow: TextOverflow.ellipsis),
            onPressed: () => context.go('/location-permission'),
          ),
          IconButton(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }
}

class _BreakingStrip extends StatelessWidget {
  final VoidCallback onRestricted;

  const _BreakingStrip({required this.onRestricted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFB51724),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Breaking local updates are live now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onRestricted,
            child: const Text('Alerts', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  final GuestHomeState state;

  const _CategoryChips({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = state.categories.take(10).toList();
    if (cats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isAll = index == 0;
          final cat = isAll ? null : cats[index - 1];
          final selected = isAll
              ? state.selectedCategoryId == null
              : state.selectedCategoryId == cat!.id;
          return ChoiceChip(
            selected: selected,
            label: Text(isAll ? 'Top News' : cat!.name),
            onSelected: (_) => ref
                .read(guestHomeNotifierProvider.notifier)
                .load(categoryId: isAll ? null : cat!.id),
          );
        },
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  final List<Article> items;

  const _FeaturedCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _FeaturedCarouselPager(items: items);
  }
}

class _FeaturedCarouselPager extends StatefulWidget {
  final List<Article> items;

  const _FeaturedCarouselPager({required this.items});

  @override
  State<_FeaturedCarouselPager> createState() => _FeaturedCarouselPagerState();
}

class _FeaturedCarouselPagerState extends State<_FeaturedCarouselPager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        padEnds: false,
        controller: _controller,
        itemCount: widget.items.length,
        itemBuilder: (_, index) => _HeroNewsCard(article: widget.items[index]),
      ),
    );
  }
}

class _HeroNewsCard extends ConsumerWidget {
  final Article article;

  const _HeroNewsCard({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openArticle(context, ref, article.slug),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 8, 12),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.black12,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (article.imageUrl != null)
              CachedNetworkImage(
                imageUrl: article.imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 900,
                placeholder: (_, __) => const _ShimmerBox(borderRadius: 22),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Colors.black12),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _MiniChip(
                    text: article.categoryName ?? 'Featured',
                    dark: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openArticle(BuildContext context, WidgetRef ref, String slug) {
    final auth = ref.read(authNotifierProvider);
    if (auth.status == AuthStatus.authenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: slug)),
      );
      return;
    }
    context.go('/guest-article/$slug');
  }
}

class _TrendingStories extends StatelessWidget {
  final List<Article> items;

  const _TrendingStories({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Trending stories'),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final article = items[index];
              return Container(
                width: 210,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniChip(text: article.categoryName ?? 'News'),
                    const Spacer(),
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VideoStrip extends StatelessWidget {
  final List<VideoItem> items;
  final VoidCallback onRestricted;

  const _VideoStrip({required this.items, required this.onRestricted});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Limited videos'),
        SizedBox(
          height: 152,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final video = items[index];
              return GestureDetector(
                onTap: index < 2 ? () {} : onRestricted,
                child: Container(
                  width: 128,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (video.thumbnail != null)
                        CachedNetworkImage(
                          imageUrl: video.thumbnail!,
                          fit: BoxFit.cover,
                          memCacheWidth: 360,
                          placeholder: (_, __) =>
                              const _ShimmerBox(borderRadius: 18),
                          errorWidget: (_, __, ___) =>
                              const ColoredBox(color: Colors.black12),
                        ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _SponsoredBand extends StatelessWidget {
  final List<AdItem> ads;

  const _SponsoredBand({required this.ads});

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) return const _GoogleAdPlaceholder();
    return _SponsoredArticleCard(ad: ads.first);
  }
}

class _PreviewArticleCard extends ConsumerWidget {
  final Article article;
  final VoidCallback onRestricted;

  const _PreviewArticleCard({
    required this.article,
    required this.onRestricted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: article.imageUrl == null
                ? Container(
                    width: 96,
                    height: 84,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  )
                : CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    width: 96,
                    height: 84,
                    fit: BoxFit.cover,
                    memCacheWidth: 260,
                    placeholder: (_, __) => const _ShimmerBox(
                      width: 96,
                      height: 84,
                      borderRadius: 14,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 96,
                      height: 84,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniChip(text: article.categoryName ?? 'News'),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (article.excerpt != null)
                  Text(
                    article.excerpt!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _openArticle(context, ref, article.slug),
                      child: const Text('Read preview'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRestricted,
                      icon: const Icon(Icons.bookmark_border_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openArticle(BuildContext context, WidgetRef ref, String slug) {
    final auth = ref.read(authNotifierProvider);
    if (auth.status == AuthStatus.authenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: slug)),
      );
      return;
    }
    context.go('/guest-article/$slug');
  }
}

class _SponsoredArticleCard extends ConsumerWidget {
  final AdItem ad;

  const _SponsoredArticleCard({required this.ad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC857).withAlpha(130)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ad.imageUrl.isEmpty
                  ? Container(
                      width: 82,
                      height: 68,
                      color: const Color(0xFFFFF3D4),
                      child: const Icon(Icons.campaign_rounded),
                    )
                  : CachedNetworkImage(
                      imageUrl: ad.imageUrl,
                      width: 82,
                      height: 68,
                      fit: BoxFit.cover,
                      memCacheWidth: 240,
                      placeholder: (_, __) => const _ShimmerBox(
                        width: 82,
                        height: 68,
                        borderRadius: 14,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 82,
                        height: 68,
                        color: const Color(0xFFFFF3D4),
                        child: const Icon(Icons.campaign_rounded),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sponsored',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A5A00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonal(
                      onPressed: ad.targetUrl.isEmpty
                          ? null
                          : () async {
                              await ref
                                  .read(adsRepositoryProvider)
                                  .trackClick(ad.id, ad.targetUrl);
                              final uri = Uri.tryParse(ad.targetUrl);
                              if (uri != null) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                      child: const Text('Learn More'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleAdPlaceholder extends StatelessWidget {
  const _GoogleAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.ads_click_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Google Ad',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                'Sponsored placement',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UnlockVaradhiCard extends StatelessWidget {
  const UnlockVaradhiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF151A24), Color(0xFF2B1A22)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Unlock Full VARADHI Experience',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _UnlockBenefit(text: 'Unlimited News'),
          const _UnlockBenefit(text: 'Breaking Alerts'),
          const _UnlockBenefit(text: 'Bookmark Stories'),
          const _UnlockBenefit(text: 'Poll Participation'),
          const _UnlockBenefit(text: 'Community Reporting'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlockBenefit extends StatelessWidget {
  final String text;

  const _UnlockBenefit({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFFFFC857),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline Mode - Showing Saved News',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _UnlockFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 10), Text(text)],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final bool dark;

  const _MiniChip({required this.text, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withAlpha(40)
            : Theme.of(context).colorScheme.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: dark ? Colors.white : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _GuestLoading extends StatelessWidget {
  const _GuestLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeaturedCarouselSkeleton(),
        _SectionTitle(title: 'Trending stories'),
        SizedBox(
          height: 130,
          child: Row(
            children: [
              SizedBox(width: 16),
              Expanded(child: ArticleCardSkeleton(compact: true)),
              SizedBox(width: 10),
              Expanded(child: ArticleCardSkeleton(compact: true)),
              SizedBox(width: 16),
            ],
          ),
        ),
        _SectionTitle(title: 'Limited videos'),
        VideoCardSkeleton(),
        _SectionTitle(title: 'Read previews'),
        ArticleCardSkeleton(),
        ArticleCardSkeleton(),
      ],
    );
  }
}

class FeaturedCarouselSkeleton extends StatelessWidget {
  const FeaturedCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 24, 12),
      child: _ShimmerBox(height: 228, borderRadius: 22),
    );
  }
}

class ArticleCardSkeleton extends StatelessWidget {
  final bool compact;

  const ArticleCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const _ShimmerBox(height: 126, borderRadius: 18);
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 96, height: 84, borderRadius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 74, height: 18, borderRadius: 8),
                SizedBox(height: 10),
                _ShimmerBox(height: 16, borderRadius: 8),
                SizedBox(height: 8),
                _ShimmerBox(width: 180, height: 16, borderRadius: 8),
                SizedBox(height: 12),
                _ShimmerBox(width: 96, height: 26, borderRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 152,
      child: Row(
        children: [
          SizedBox(width: 16),
          _ShimmerBox(width: 128, height: 152, borderRadius: 18),
          SizedBox(width: 10),
          _ShimmerBox(width: 128, height: 152, borderRadius: 18),
          SizedBox(width: 10),
          _ShimmerBox(width: 128, height: 152, borderRadius: 18),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const _ShimmerBox({this.width, this.height, this.borderRadius = 12});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
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
      builder: (context, _) {
        return Container(
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
        );
      },
    );
  }
}

class _GuestEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _GuestEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.newspaper_rounded,
              size: 64,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'No news available',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back shortly',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Could not load guest feed: $message'),
    );
  }
}
