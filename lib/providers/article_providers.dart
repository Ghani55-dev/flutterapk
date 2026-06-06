import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../features/article/data/article_remote_datasource.dart';
import '../features/article/data/article_repository.dart';
import '../features/article/article_notifier.dart';

final articleRemoteProvider = Provider((ref) {
  final api = ref.read(apiClientProvider);
  return ArticleRemoteDataSource(apiClient: api);
});

final articleRepositoryProvider = Provider((ref) {
  final remote = ref.read(articleRemoteProvider);
  final storage = ref.read(secureStorageProvider);
  return ArticleRepository(remote: remote, storage: storage);
});

final articleNotifierProvider = StateNotifierProvider.family<ArticleNotifier, dynamic, String>((ref, slug) {
  final repo = ref.read(articleRepositoryProvider);
  final notifier = ArticleNotifier(repository: repo);
  notifier.load(slug);
  return notifier;
});
