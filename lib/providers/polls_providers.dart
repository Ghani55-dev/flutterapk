import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';
import '../features/polls/data/polls_remote_datasource.dart';
import '../features/polls/data/polls_repository.dart';
import '../features/polls/polls_notifier.dart';
// secure storage provided via core_providers

final pollsRemoteProvider = Provider((ref) => PollsRemoteDataSource(apiClient: ref.read(apiClientProvider)));
final pollsRepositoryProvider = Provider((ref) => PollsRepository(remote: ref.read(pollsRemoteProvider), apiClient: ref.read(apiClientProvider)));
final pollsNotifierProvider = StateNotifierProvider<PollsNotifier, PollsState>((ref) => PollsNotifier(ref: ref, repository: ref.read(pollsRepositoryProvider), storage: ref.read(secureStorageProvider)));
