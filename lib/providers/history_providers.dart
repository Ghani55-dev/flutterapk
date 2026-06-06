import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/history/data/history_repository.dart';
import '../features/history/history_notifier.dart';
import 'core_providers.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository(storage: ref.read(secureStorageProvider)));
final historyNotifierProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) => HistoryNotifier(repository: ref.read(historyRepositoryProvider)));
