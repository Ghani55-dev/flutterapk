import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/data/ads_repository.dart';
import '../ads/models.dart';
import '../home/data/home_repository.dart';
import '../home/data/models.dart';
import '../location/location_provider.dart';
import '../reels/models.dart';
import '../../providers/ads_providers.dart';
import '../../providers/home_providers.dart';

final guestHomeNotifierProvider = StateNotifierProvider<GuestHomeNotifier, GuestHomeState>((ref) {
  return GuestHomeNotifier(
    ref: ref,
    homeRepository: ref.read(homeRepositoryProvider),
    adsRepository: ref.read(adsRepositoryProvider),
  );
});

class GuestHomeState {
  final List<Article> articles;
  final List<Article> featured;
  final List<Article> trending;
  final List<VideoItem> videos;
  final List<CategoryModel> categories;
  final List<AdItem> ads;
  final bool loading;
  final bool offline;
  final bool showingCachedData;
  final String? error;
  final String? selectedCategoryId;

  const GuestHomeState({
    this.articles = const [],
    this.featured = const [],
    this.trending = const [],
    this.videos = const [],
    this.categories = const [],
    this.ads = const [],
    this.loading = false,
    this.offline = false,
    this.showingCachedData = false,
    this.error,
    this.selectedCategoryId,
  });

  GuestHomeState copyWith({
    List<Article>? articles,
    List<Article>? featured,
    List<Article>? trending,
    List<VideoItem>? videos,
    List<CategoryModel>? categories,
    List<AdItem>? ads,
    bool? loading,
    bool? offline,
    bool? showingCachedData,
    String? error,
    String? selectedCategoryId,
  }) {
    return GuestHomeState(
      articles: articles ?? this.articles,
      featured: featured ?? this.featured,
      trending: trending ?? this.trending,
      videos: videos ?? this.videos,
      categories: categories ?? this.categories,
      ads: ads ?? this.ads,
      loading: loading ?? this.loading,
      offline: offline ?? this.offline,
      showingCachedData: showingCachedData ?? this.showingCachedData,
      error: error,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class GuestHomeNotifier extends StateNotifier<GuestHomeState> {
  final Ref ref;
  final HomeRepository homeRepository;
  final AdsRepository adsRepository;

  GuestHomeNotifier({
    required this.ref,
    required this.homeRepository,
    required this.adsRepository,
  }) : super(const GuestHomeState(loading: true)) {
    load();
  }

  Future<void> load({String? categoryId}) async {
    state = state.copyWith(
      loading: true,
      error: null,
      offline: false,
      showingCachedData: false,
      selectedCategoryId: categoryId,
    );

    try {
      final loc = _location();
      final results = await Future.wait<dynamic>([
        homeRepository.getCategories(),
        homeRepository.getFeatured(state: loc?['state'], district: loc?['district'], city: loc?['city']),
        homeRepository.getFeed(
          page: 1,
          pageSize: 8,
          categoryId: categoryId,
          state: loc?['state'],
          district: loc?['district'],
          city: loc?['city'],
        ),
        homeRepository.getVideoPreviews(),
        adsRepository.fetchAds(zone: 'guest_feed', state: loc?['state'], district: loc?['district'], city: loc?['city']),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final featured = results[1] as List<Article>;
      final feed = results[2] as PaginatedArticles;
      final videos = (results[3] as List<VideoItem>).take(5).toList();
      final ads = results[4] as List<AdItem>;
      final trending = [...featured, ...feed.results].where((e) => e.title.isNotEmpty).take(6).toList();

      if (!mounted) return;
      state = state.copyWith(
        categories: categories,
        featured: featured.take(5).toList(),
        articles: feed.results.take(8).toList(),
        trending: trending,
        videos: videos,
        ads: ads,
        loading: false,
        offline: false,
        showingCachedData: false,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      if (_isNetworkError(e)) {
        final cached = await homeRepository.getCachedFeed();
        if (cached != null && cached.results.isNotEmpty) {
          final cachedArticles = cached.results.take(8).toList();
          state = state.copyWith(
            articles: cachedArticles,
            trending: cachedArticles.take(6).toList(),
            loading: false,
            offline: true,
            showingCachedData: true,
            error: null,
          );
          return;
        }

        state = state.copyWith(
          loading: false,
          offline: true,
          showingCachedData: false,
          error: 'You appear to be offline. Pull to refresh when the connection returns.',
        );
        return;
      }

      state = state.copyWith(loading: false, offline: false, showingCachedData: false, error: e.toString());
    }
  }

  Map<String, String>? _location() {
    final value = ref.read(locationProvider);
    if (value is AsyncData<Map<String, String>?>) return value.value;
    return null;
  }

  bool _isNetworkError(Object error) {
    if (error is! DioException) return false;
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;
  }
}
