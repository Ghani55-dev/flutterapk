import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/cms_providers.dart';
import 'package:flutter_html/flutter_html.dart';

class CmsPageScreen extends ConsumerWidget {
  final String slug;
  final String? titleFallback;
  const CmsPageScreen({super.key, required this.slug, this.titleFallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cmsNotifierProvider);
    final notifier = ref.read(cmsNotifierProvider.notifier);
    final loaded = state.page;

    if (state.page == null || state.page?.slug != slug) {
      // trigger load
      Future.microtask(() => notifier.loadPage(slug));
    }

    return Scaffold(
      appBar: AppBar(title: Text(loaded?.title ?? titleFallback ?? 'Page')),
      body: state.loading && loaded == null
          ? const Center(child: CircularProgressIndicator())
          : loaded == null
              ? const Center(child: Text('Page not found'))
              : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Html(data: loaded.content)),
    );
  }
}
