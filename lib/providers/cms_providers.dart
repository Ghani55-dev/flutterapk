import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../features/cms/data/cms_remote_datasource.dart';
import '../features/cms/data/cms_repository.dart';
import '../features/cms/cms_notifier.dart';

final cmsRemoteProvider = Provider((ref) => CmsRemoteDataSource(apiClient: ref.read(apiClientProvider)));
final cmsRepositoryProvider = Provider((ref) => CmsRepository(remote: ref.read(cmsRemoteProvider)));
final cmsNotifierProvider = StateNotifierProvider<CmsNotifier, CmsState>((ref) => CmsNotifier(repository: ref.read(cmsRepositoryProvider)));
