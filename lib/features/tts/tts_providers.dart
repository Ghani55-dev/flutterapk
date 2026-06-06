import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tts/tts_notifier.dart';
import 'data/tts_remote_datasource.dart';
import 'data/tts_repository.dart';
import '../../providers/core_providers.dart';

final ttsRemoteProvider = Provider((ref) => TtsRemoteDataSource(apiClient: ref.read(apiClientProvider)));
final ttsRepositoryProvider = Provider((ref) => TtsRepository(remote: ref.read(ttsRemoteProvider)));
final ttsNotifierProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) => TtsNotifier(repository: ref.read(ttsRepositoryProvider)));
