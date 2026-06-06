import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'data/models.dart';
import 'data/home_repository.dart';
import '../location/location_provider.dart';
import '../reels/models.dart';
import '../epaper/models.dart';
import '../../providers/settings_providers.dart';

class FeedState {
  final List<Article> items;
  final List<Article> featured;
  final List<Map<String, dynamic>> liveNews;
  final Map<String, dynamic>? quote;
  final List<Article> recommendations;
  final List<VideoItem> videoPreviews;
  final List<VideoItem> shortsPreviews;
  final List<Epaper> epapers;
  final List<Map<String, dynamic>> cmsBlocks;
  final bool ttsAvailable;
  final bool modulesLoading;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final bool offline;
  final bool showingCachedData;
  final String? error;
  final int page;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;

  FeedState({
    required this.items,
    this.featured = const [],
    this.liveNews = const [],
    this.quote,
    this.recommendations = const [],
    this.videoPreviews = const [],
    this.shortsPreviews = const [],
    this.epapers = const [],
    this.cmsBlocks = const [],
    this.ttsAvailable = false,
    this.modulesLoading = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.offline = false,
    this.showingCachedData = false,
    this.error,
    this.page = 1,
    this.categories = const [],
    this.selectedCategoryId,
  });

  FeedState copyWith({
    List<Article>? items,
    List<Article>? featured,
    List<Map<String, dynamic>>? liveNews,
    Map<String, dynamic>? quote,
    bool clearQuote = false,
    List<Article>? recommendations,
    List<VideoItem>? videoPreviews,
    List<VideoItem>? shortsPreviews,
    List<Epaper>? epapers,
    List<Map<String, dynamic>>? cmsBlocks,
    bool? ttsAvailable,
    bool? modulesLoading,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    bool? offline,
    bool? showingCachedData,
    String? error,
    int? page,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
  }) =>
      FeedState(
        items: items ?? this.items,
        featured: featured ?? this.featured,
        liveNews: liveNews ?? this.liveNews,
        quote: clearQuote ? null : (quote ?? this.quote),
        recommendations: recommendations ?? this.recommendations,
        videoPreviews: videoPreviews ?? this.videoPreviews,
        shortsPreviews: shortsPreviews ?? this.shortsPreviews,
        epapers: epapers ?? this.epapers,
        cmsBlocks: cmsBlocks ?? this.cmsBlocks,
        ttsAvailable: ttsAvailable ?? this.ttsAvailable,
        modulesLoading: modulesLoading ?? this.modulesLoading,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        hasMore: hasMore ?? this.hasMore,
        offline: offline ?? this.offline,
        showingCachedData: showingCachedData ?? this.showingCachedData,
        error: error,
        page: page ?? this.page,
        categories: categories ?? this.categories,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      );
}

class FeedNotifier extends StateNotifier<FeedState> {
  final HomeRepository repository;
  final int pageSize;
  final Ref ref;
  String? activeCategoryId;

  FeedNotifier({required this.ref, required this.repository, this.pageSize = 20}) : super(FeedState(items: [])) {
    _restoreCache();
    fetchFirstPage();
    loadCategories();
    loadHomeModules();
  }

  Future<void> loadCategories() async {
    try {
      final cats = await repository.getCategories();
      if (mounted) {
        state = state.copyWith(categories: cats);
      }
    } catch (_) {}
  }

  Future<void> _restoreCache() async {
    try {
      final cached = await repository.getCachedFeed();
      if (cached != null && mounted) {
        state = state.copyWith(items: cached.results, page: cached.page, hasMore: (cached.total == null) ? true : (cached.results.length < (cached.total ?? 0)));
      }
    } catch (_) {}
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      // Resolve location context (if available) to pass to backend
      final locAv = ref.read(locationProvider);
      Map<String, String>? loc;
      if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      // include language preference if set
      final settings = ref.read(settingsNotifierProvider);
      final lang = settings.language;
      if (kDebugMode) debugPrint('[FILTER PARAMS] category=$activeCategoryId state=${loc?['state']} district=${loc?['district']} city=${loc?['city']} lang=$lang');
      final res = await repository.getFeed(
        page: 1,
        pageSize: pageSize,
        categoryId: activeCategoryId,
        language: lang,
        state: loc?['state'],
        district: loc?['district'],
        city: loc?['city'],
      );
      state = state.copyWith(items: res.results, isLoading: false, hasMore: (res.results.length >= pageSize), page: 1, offline: false, showingCachedData: false);
    } catch (e, st) {
      if (kDebugMode) debugPrint('Feed fetch error $e $st');
      await _restoreCachedFeedAfterNetworkError(e);
    }
  }

  Future<void> loadHomeModules() async {
    state = state.copyWith(modulesLoading: true);
    final locAv = ref.read(locationProvider);
    Map<String, String>? loc;
    if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;

    List<Article> featured = [];
    List<Map<String, dynamic>> live = [];
    Map<String, dynamic>? quote;
    List<VideoItem> videos = [];
    List<VideoItem> shorts = [];
    List<Epaper> epapers = [];
    List<Article> recs = [];
    List<Map<String, dynamic>> cms = [];
    bool tts = false;

    try {
      featured = await repository.getFeatured(state: loc?['state'], district: loc?['district'], city: loc?['city']);
    } catch (e) {
      if (kDebugMode) debugPrint('Featured load failed: $e');
    }
    try {
      live = await repository.getLiveNews();
    } catch (e) {
      if (kDebugMode) debugPrint('Live news load failed: $e');
    }
    try {
      quote = await repository.getQuote();
    } catch (e) {
      if (kDebugMode) debugPrint('Quote load failed: $e');
    }
    try {
      videos = await repository.getVideoPreviews();
    } catch (e) {
      if (kDebugMode) debugPrint('Video previews load failed: $e');
    }
    try {
      shorts = await repository.getShortsPreviews();
    } catch (e) {
      if (kDebugMode) debugPrint('Shorts load failed: $e');
    }
    try {
      epapers = await repository.getEpapers();
    } catch (e) {
      if (kDebugMode) debugPrint('Epapers load failed: $e');
    }
    try {
      recs = await repository.getRecommendations();
    } catch (e) {
      if (kDebugMode) debugPrint('Recommendations load failed: $e');
    }
    try {
      cms = await repository.getCmsBlocks();
    } catch (e) {
      if (kDebugMode) debugPrint('CMS blocks load failed: $e');
    }
    try {
      tts = await repository.getTtsAvailability();
    } catch (e) {
      if (kDebugMode) debugPrint('TTS availability check failed: $e');
    }

    if (!mounted) return;
    state = state.copyWith(
      featured: featured,
      liveNews: live,
      quote: quote,
      videoPreviews: videos,
      shortsPreviews: shorts,
      epapers: epapers,
      recommendations: recs,
      cmsBlocks: cms,
      ttsAvailable: tts,
      modulesLoading: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final locAv = ref.read(locationProvider);
      Map<String, String>? loc;
      if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      final settings = ref.read(settingsNotifierProvider);
      final lang = settings.language;
      final res = await repository.getFeed(page: 1, pageSize: pageSize, categoryId: activeCategoryId, language: lang, state: loc?['state'], district: loc?['district'], city: loc?['city']);
      state = state.copyWith(items: res.results, isRefreshing: false, hasMore: (res.results.length >= pageSize), page: 1, offline: false, showingCachedData: false);
      loadHomeModules();
    } catch (e) {
      await _restoreCachedFeedAfterNetworkError(e);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    final next = state.page + 1;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locAv = ref.read(locationProvider);
      Map<String, String>? loc;
      if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      final settings = ref.read(settingsNotifierProvider);
      final lang = settings.language;
      final res = await repository.getFeed(page: next, pageSize: pageSize, categoryId: activeCategoryId, language: lang, state: loc?['state'], district: loc?['district'], city: loc?['city']);
      final combined = List<Article>.from(state.items)..addAll(res.results);
      state = state.copyWith(items: combined, isLoading: false, hasMore: (res.results.length >= pageSize), page: next, offline: false, showingCachedData: false);
    } catch (e) {
      final hasReadableItems = state.items.isNotEmpty;
      state = state.copyWith(
        isLoading: false,
        offline: _isNetworkError(e),
        showingCachedData: hasReadableItems && _isNetworkError(e),
        error: hasReadableItems && _isNetworkError(e) ? null : e.toString(),
      );
    }
  }

  void setCategory(String? catId) {
    try {
      if (kDebugMode) debugPrint('[FILTER CLICK] category=$catId');
    } catch (_) {}
    // toggle: if same category tapped twice, clear filter
    if (activeCategoryId == catId) {
      activeCategoryId = null;
      state = state.copyWith(items: [], page: 1, hasMore: true, error: null, selectedCategoryId: null);
    } else {
      activeCategoryId = catId;
      state = state.copyWith(items: [], page: 1, hasMore: true, error: null, selectedCategoryId: catId);
    }
    if (kDebugMode) debugPrint('[FILTER APPLY] activeCategory=$activeCategoryId');
    fetchFirstPage();
  }

  Future<void> _restoreCachedFeedAfterNetworkError(Object error) async {
    final networkError = _isNetworkError(error);
    if (networkError) {
      final cached = await repository.getCachedFeed();
      if (cached != null && mounted && cached.results.isNotEmpty) {
        state = state.copyWith(
          items: cached.results,
          isLoading: false,
          isRefreshing: false,
          hasMore: false,
          page: cached.page,
          offline: true,
          showingCachedData: true,
          error: null,
        );
        return;
      }
    }

    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      offline: networkError,
      showingCachedData: false,
      error: error.toString(),
    );
  }

  bool _isNetworkError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
    }
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') || text.contains('connection') || text.contains('network') || text.contains('timeout');
  }
}
