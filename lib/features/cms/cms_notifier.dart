import 'package:state_notifier/state_notifier.dart';
import 'data/cms_repository.dart';
import 'models.dart';

class CmsState {
  final bool loading;
  final CmsPage? page;
  final List<CmsPage> pages;
  CmsState({this.loading = false, this.page, this.pages = const []});
  CmsState copyWith({bool? loading, CmsPage? page, List<CmsPage>? pages}) => CmsState(loading: loading ?? this.loading, page: page ?? this.page, pages: pages ?? this.pages);
}

class CmsNotifier extends StateNotifier<CmsState> {
  final CmsRepository repository;
  CmsNotifier({required this.repository}) : super(CmsState());

  Future<void> loadPages() async {
    state = state.copyWith(loading: true);
    final list = await repository.listPages();
    state = state.copyWith(loading: false, pages: list);
  }

  Future<void> loadPage(String slug) async {
    state = state.copyWith(loading: true);
    final p = await repository.getPage(slug);
    state = state.copyWith(loading: false, page: p);
  }
}
