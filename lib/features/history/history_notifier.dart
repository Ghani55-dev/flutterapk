import 'package:state_notifier/state_notifier.dart';
import 'data/history_repository.dart';

class HistoryState {
  final bool loading;
  final List<Map<String, dynamic>> items;
  HistoryState({this.loading = false, this.items = const []});
  HistoryState copyWith({bool? loading, List<Map<String, dynamic>>? items}) => HistoryState(loading: loading ?? this.loading, items: items ?? this.items);
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRepository repository;
  HistoryNotifier({required this.repository}) : super(HistoryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    final items = await repository.list();
    state = state.copyWith(loading: false, items: items);
  }

  Future<void> add(Map<String, dynamic> article) async {
    // expects article minimal map with slug/title
    // wrap into Article model at repository layer; but repository accepts Article objects, so callers should call repository.add
  }

  Future<void> clear() async {
    await repository.clear();
    state = state.copyWith(items: []);
  }
}
