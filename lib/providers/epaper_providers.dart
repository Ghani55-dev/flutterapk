import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../features/epaper/data/epaper_remote_datasource.dart';
import '../features/epaper/data/epaper_repository.dart';
import '../features/epaper/epaper_notifier.dart';

final epaperRemoteProvider = Provider((ref) => EpaperRemoteDataSource(apiClient: ref.read(apiClientProvider)));
final epaperRepositoryProvider = Provider((ref) => EpaperRepository(remote: ref.read(epaperRemoteProvider)));
final epaperNotifierProvider = StateNotifierProvider<EpaperNotifier, EpaperState>((ref) => EpaperNotifier(repository: ref.read(epaperRepositoryProvider)));
