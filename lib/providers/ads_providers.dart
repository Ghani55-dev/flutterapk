import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../features/ads/data/ads_remote_datasource.dart';
import '../features/ads/data/ads_repository.dart';

final adsRemoteProvider = Provider((ref) {
  final api = ref.read(apiClientProvider);
  return AdsRemoteDataSource(apiClient: api);
});

final adsRepositoryProvider = Provider((ref) {
  final remote = ref.read(adsRemoteProvider);
  return AdsRepository(remote: remote);
});
