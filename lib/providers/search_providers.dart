import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../features/search/data/search_remote_datasource.dart';
import '../features/search/data/search_repository.dart';
import '../features/search/search_notifier.dart';

final searchRemoteProvider = Provider((ref) {
  final api = ref.read(apiClientProvider);
  return SearchRemoteDataSource(apiClient: api);
});

final searchRepositoryProvider = Provider((ref) {
  final remote = ref.read(searchRemoteProvider);
  final storage = ref.read(secureStorageProvider);
  return SearchRepository(remote: remote, storage: storage);
});

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, dynamic>((ref) {
  final repo = ref.read(searchRepositoryProvider);
  return SearchNotifier(ref: ref, repository: repo);
});
