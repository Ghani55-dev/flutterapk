import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../features/bookmarks/data/bookmarks_remote_datasource.dart';
import '../features/bookmarks/data/bookmarks_repository.dart';
import '../features/bookmarks/bookmarks_notifier.dart';

final bookmarksRemoteProvider = Provider((ref) => BookmarksRemoteDataSource(apiClient: ref.read(apiClientProvider)));
final bookmarksRepositoryProvider = Provider((ref) => BookmarksRepository(remote: ref.read(bookmarksRemoteProvider)));
final bookmarksNotifierProvider = StateNotifierProvider<BookmarksNotifier, BookmarksState>((ref) => BookmarksNotifier(repository: ref.read(bookmarksRepositoryProvider)));
