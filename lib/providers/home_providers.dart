import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/data/home_remote_datasource.dart';
import '../features/home/data/home_repository.dart';
import '../features/home/home_notifier.dart';
import 'core_providers.dart';

final homeRemoteProvider = Provider<HomeRemoteDataSource>((ref) {
  final api = ref.read(apiClientProvider);
  return HomeRemoteDataSource(apiClient: api);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final remote = ref.read(homeRemoteProvider);
  final storage = ref.read(secureStorageProvider);
  return HomeRepository(remote: remote, storage: storage);
});

final feedNotifierProvider = StateNotifierProvider<FeedNotifier, dynamic>((ref) {
  final repo = ref.read(homeRepositoryProvider);
  return FeedNotifier(ref: ref, repository: repo);
});
