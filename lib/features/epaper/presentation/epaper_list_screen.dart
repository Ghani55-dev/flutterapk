import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/epaper_providers.dart';
import 'epaper_card.dart';

class EpaperListScreen extends ConsumerWidget {
  const EpaperListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(epaperNotifierProvider);
    final notifier = ref.read(epaperNotifierProvider.notifier);

    if (state.items.isEmpty && !state.loading) {
      // load if not present
      Future.microtask(() => notifier.loadList());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('E-Papers')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? const Center(child: Text('No editions yet'))
              : ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (c, i) {
                    final e = state.items[i];
                    return EpaperCard(
                      epaper: e,
                      onTap: () {
                        try {
                          if (kDebugMode) debugPrint('[EPAPER CLICK] id=${e.id} title=${e.title}');
                          if (kDebugMode) debugPrint('[PDF URL] ${e.pdfUrl}');
                        } catch (_) {}
                        if (kDebugMode) debugPrint('[EPAPER NAV] LIST -> LANDING id=${e.id}');
                        context.push('/epapers/${e.id}');
                      },
                    );
                  },
                ),
    );
  }
}
