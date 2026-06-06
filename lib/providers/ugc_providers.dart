import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/ugc/data/ugc_remote_datasource.dart';
import '../features/ugc/data/ugc_repository.dart';
import '../features/ugc/ugc_notifier.dart';
import 'core_providers.dart';

final ugcRemoteProvider = Provider<UGCRemoteDataSource>((ref) {
  return UGCRemoteDataSource(apiClient: ref.read(apiClientProvider));
});

final ugcRepositoryProvider = Provider<UGCRepository>((ref) {
  return UGCRepository(
    remote: ref.read(ugcRemoteProvider),
    storage: ref.read(secureStorageProvider),
  );
});

final ugcProvider = StateNotifierProvider<UGCNotifier, UGCState>((ref) {
  return UGCNotifier(repository: ref.read(ugcRepositoryProvider));
});
