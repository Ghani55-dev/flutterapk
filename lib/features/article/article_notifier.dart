import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'data/models.dart';
import 'data/article_repository.dart';

class ArticleState {
  final ArticleDetail? article;
  final bool isLoading;
  final String? error;
  final bool ttsRequested;
  final List<ArticleDetail> related;

  ArticleState({this.article, this.isLoading = false, this.error, this.ttsRequested = false, this.related = const []});

  ArticleState copyWith({ArticleDetail? article, bool? isLoading, String? error, bool? ttsRequested, List<ArticleDetail>? related}) =>
      ArticleState(article: article ?? this.article, isLoading: isLoading ?? this.isLoading, error: error, ttsRequested: ttsRequested ?? this.ttsRequested, related: related ?? this.related);
}

class ArticleNotifier extends StateNotifier<ArticleState> {
  final ArticleRepository repository;

  ArticleNotifier({required this.repository}) : super(ArticleState());

  Future<void> load(String slug) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await repository.getDetail(slug);
      final related = await repository.getRelated(detail.categorySlug);
      state = state.copyWith(article: detail, isLoading: false, related: related);
    } catch (e) {
      if (kDebugMode) debugPrint('Article load error $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleBookmark() async {
    final id = state.article?.id;
    if (id == null) return;
    // optimistic
    final prev = state.article;
    final updated = ArticleDetail(
      id: prev!.id,
      title: prev.title,
      slug: prev.slug,
      summary: prev.summary,
      content: prev.content,
      thumbnailUrl: prev.thumbnailUrl,
      authorName: prev.authorName,
      sourceName: prev.sourceName,
      publishedAt: prev.publishedAt,
      readTimeMinutes: prev.readTimeMinutes,
      isBookmarked: !prev.isBookmarked,
      tags: prev.tags,
      categorySlug: prev.categorySlug,
    );
    state = state.copyWith(article: updated);
    try {
      final ok = await repository.toggleBookmark(id);
      if (!ok) throw Exception('toggle failed');
    } catch (e) {
      // rollback
      state = state.copyWith(article: prev);
    }
  }

  Future<void> requestTTS() async {
    final id = state.article?.id;
    if (id == null) return;
    state = state.copyWith(ttsRequested: true);
    try {
      await repository.requestTTS(id);
    } catch (e) {
      if (kDebugMode) debugPrint('TTS request failed $e');
      state = state.copyWith(ttsRequested: false);
    }
  }
}
