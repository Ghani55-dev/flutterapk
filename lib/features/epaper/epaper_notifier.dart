import 'package:state_notifier/state_notifier.dart';
import 'package:flutter/foundation.dart';
import 'data/epaper_repository.dart';
import 'models.dart';

class EpaperState {
  final bool loading;
  final List<Epaper> items;
  final Epaper? selected;
  EpaperState({this.loading = false, this.items = const [], this.selected});
  EpaperState copyWith({bool? loading, List<Epaper>? items, Epaper? selected}) => EpaperState(loading: loading ?? this.loading, items: items ?? this.items, selected: selected ?? this.selected);
}

class EpaperNotifier extends StateNotifier<EpaperState> {
  final EpaperRepository repository;
  EpaperNotifier({required this.repository}) : super(EpaperState());

  Future<void> loadList() async {
    if (kDebugMode) debugPrint('[EPAPER NOTIFIER] loadList()');
    state = state.copyWith(loading: true);
    final list = await repository.list();
    if (kDebugMode) debugPrint('[EPAPER NOTIFIER] loadList() got ${list.length} items');
    state = state.copyWith(loading: false, items: list);
  }

  Future<void> loadDetail(String id) async {
    if (kDebugMode) debugPrint('[EPAPER NOTIFIER] loadDetail(id=$id)');
    state = state.copyWith(loading: true);
    final d = await repository.detail(id);
    if (kDebugMode) debugPrint('[EPAPER NOTIFIER] loadDetail selected=${d?.id}');
    state = state.copyWith(loading: false, selected: d);
  }
}
