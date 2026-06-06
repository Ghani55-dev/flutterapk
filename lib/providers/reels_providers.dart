import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../features/reels/data/video_remote_datasource.dart';
import '../features/reels/data/video_repository.dart';
import '../features/reels/video_playback_manager.dart';
import '../features/reels/reels_notifier.dart';

final reelsRemoteProvider = Provider((ref) {
  final api = ref.read(apiClientProvider);
  return VideoRemoteDataSource(apiClient: api);
});

final reelsRepositoryProvider = Provider((ref) {
  final remote = ref.read(reelsRemoteProvider);
  return VideoRepository(remote: remote);
});

final reelsPlaybackManagerProvider = Provider((ref) => VideoPlaybackManager());

final reelsNotifierProvider = StateNotifierProvider<ReelsNotifier, dynamic>((ref) {
  final repo = ref.read(reelsRepositoryProvider);
  final manager = ref.read(reelsPlaybackManagerProvider);
  return ReelsNotifier(ref: ref, repository: repo, playbackManager: manager);
});
