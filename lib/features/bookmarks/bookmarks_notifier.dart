import 'package:state_notifier/state_notifier.dart';
import 'data/bookmarks_repository.dart';
import '../home/data/models.dart';

class BookmarksState {
  final bool loading;
  final List<Article> items;
  BookmarksState({this.loading = false, this.items = const []});
  BookmarksState copyWith({bool? loading, List<Article>? items}) => BookmarksState(loading: loading ?? this.loading, items: items ?? this.items);
}

class BookmarksNotifier extends StateNotifier<BookmarksState> {
  final BookmarksRepository repository;
  BookmarksNotifier({required this.repository}) : super(BookmarksState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final items = await repository.fetchBookmarks();
      final List<Article> typed = List<Article>.from(items);
      state = BookmarksState(loading: false, items: typed);
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  /// Optimistic remove: remove locally first, attempt remote delete, rollback on failure.
  Future<void> remove(String id) async {
    final List<Article> before = List<Article>.from(state.items);
    final List<Article> updated = List<Article>.from(state.items.where((e) => e.id != id).toList());
    state = state.copyWith(items: updated);
    try {
      await repository.removeBookmark(id);
    } catch (e) {
      // rollback
      state = state.copyWith(items: before);
      rethrow;
    }
  }
}

