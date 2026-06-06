import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/search_repository.dart';
import 'package:dio/dio.dart';
import '../home/data/models.dart';
import '../location/location_provider.dart';

class SearchState {
  final String query;
  final bool isLoading;
  final List<Article> items;
  final bool hasMore;
  final String? error;
  final List<String> history;

  SearchState({this.query = '', this.isLoading = false, this.items = const [], this.hasMore = true, this.error, this.history = const []});

  SearchState copyWith({String? query, bool? isLoading, List<Article>? items, bool? hasMore, String? error, List<String>? history}) =>
      SearchState(
        query: query ?? this.query,
        isLoading: isLoading ?? this.isLoading,
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        history: history ?? this.history,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository repository;
  final int pageSize;
  final Ref ref;
  Timer? _debounce;
  CancelToken? _cancelToken;
  int _page = 1;

  SearchNotifier({required this.ref, required this.repository, this.pageSize = 20}) : super(SearchState()) {
    _initHistory();
  }

  Future<void> _initHistory() async {
    final h = await repository.getHistory();
    state = state.copyWith(history: h);
  }

  void setQuery(String q) {
    if (q.trim() == state.query.trim()) return;
    state = state.copyWith(query: q, error: null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(reset: true);
    });
  }

  Future<void> _performSearch({bool reset = false}) async {
    final q = state.query.trim();
    if (q.isEmpty) {
      state = state.copyWith(items: [], isLoading: false, hasMore: true);
      return;
    }
    if (reset) {
      _page = 1;
      state = state.copyWith(isLoading: true);
      _cancelToken?.cancel();
      _cancelToken = CancelToken();
    }
    try {
      final locAv = ref.read(locationProvider);
      Map<String, String>? loc;
      if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      final res = await repository.search(
        q: q,
        page: _page,
        pageSize: pageSize,
        category: null,
        state: loc?['state'],
        district: loc?['district'],
        city: loc?['city'],
        cancelToken: _cancelToken,
      );
      final items = res.results;
      final combined = reset ? items : List<Article>.from(state.items)..addAll(items);
      final hasMore = items.length >= pageSize;
      state = state.copyWith(items: combined, isLoading: false, hasMore: hasMore);
      if (reset) await repository.addHistory(q);
    } catch (e, st) {
      if (kDebugMode) debugPrint('Search error $e $st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    _page += 1;
    state = state.copyWith(isLoading: true);
    await _performSearch(reset: false);
  }

  Future<void> clearQuery() async {
    state = state.copyWith(query: '', items: [], error: null);
  }

  Future<void> removeHistoryItem(String q) async {
    await repository.removeHistory(q);
    final h = await repository.getHistory();
    state = state.copyWith(history: h);
  }

  Future<void> clearHistory() async {
    await repository.clearHistory();
    state = state.copyWith(history: []);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}
