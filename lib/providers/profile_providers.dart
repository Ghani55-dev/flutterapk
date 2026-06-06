import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../features/profile/data/profile_remote_datasource.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/profile_notifier.dart';

final profileRemoteProvider = Provider((ref) => ProfileRemoteDataSource(apiClient: ref.read(apiClientProvider)));
final profileRepositoryProvider = Provider((ref) => ProfileRepository(remote: ref.read(profileRemoteProvider)));
final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) => ProfileNotifier(repository: ref.read(profileRepositoryProvider)));
