import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models.dart';
import '../../../providers/epaper_providers.dart';

class EpaperLandingScreen extends ConsumerStatefulWidget {
  final Epaper? epaper;
  final String? id;
  const EpaperLandingScreen({super.key, this.epaper, this.id}) : assert(epaper != null || id != null);

  @override
  ConsumerState<EpaperLandingScreen> createState() => _EpaperLandingScreenState();
}

class _EpaperLandingScreenState extends ConsumerState<EpaperLandingScreen> {
  PdfControllerPinch? _controller;
  bool _loading = false;
  double _progress = 0.0;
  String? _error;
  int _currentPage = 1;
  int _pageCount = 0;
  String? _cachedPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.epaper == null && widget.id != null) {
        ref.read(epaperNotifierProvider.notifier).loadDetail(widget.id!);
      } else if (widget.epaper != null) {
        _openEpaper(widget.epaper);
      }
    });
  }

  Future<void> _openEpaper(Epaper? epaper) async {
    final ep = epaper ?? ref.read(epaperNotifierProvider).selected;
    if (ep == null) return;
    final url = ep.pdfUrl;
    if (url.isEmpty) {
      setState(() => _error = 'No PDF URL available');
      if (kDebugMode) debugPrint('[EPAPER OPEN] missing url for ${ep.id}');
      return;
    }

    if (kDebugMode) debugPrint('[EPAPER OPEN] id=${ep.id} title=${ep.title}');
    if (kDebugMode) debugPrint('[PDF URL] $url');
    if (kDebugMode) debugPrint('[EPAPER SCREEN] LANDING open pdf=${ep.pdfUrl}');

    setState(() {
      _loading = true;
      _progress = 0.0;
      _error = null;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${ep.id}.pdf');
      if (await file.exists()) {
        _cachedPath = file.path;
        final futureDoc = PdfDocument.openFile(file.path);
        _controller = PdfControllerPinch(document: futureDoc);
        final doc = await futureDoc;
        _pageCount = doc.pagesCount;
        if (kDebugMode) debugPrint('[PDF LOAD SUCCESS] cached path=${file.path}');
        setState(() {
          _loading = false;
        });
        return;
      }

      final dio = Dio();
      final resp = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes), onReceiveProgress: (received, total) {
        if (total != -1) setState(() => _progress = received / total);
      });
      if (resp.statusCode != 200) throw Exception('Download failed: ${resp.statusCode}');
      final bytes = resp.data ?? <int>[];
      await file.writeAsBytes(bytes, flush: true);
      _cachedPath = file.path;
      final futureDoc = PdfDocument.openFile(file.path);
      _controller = PdfControllerPinch(document: futureDoc);
      final doc = await futureDoc;
      _pageCount = doc.pagesCount;
      if (kDebugMode) debugPrint('[PDF LOAD SUCCESS] path=${file.path} pages=${_pageCount}');
      setState(() {
        _loading = false;
        _progress = 1.0;
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PDF LOAD FAILED] $e');
        debugPrint(st.toString());
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('[EPAPER SCREEN] LANDING id=${widget.id ?? widget.epaper?.id}');
    final epaperState = ref.watch(epaperNotifierProvider);
    final ep = widget.epaper ?? epaperState.selected;
    if (widget.epaper == null && ep == null && epaperState.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final title = ep?.title ?? 'E-Paper';
    final date = ep?.publishedAt != null ? ep!.publishedAt!.toLocal().toString().split(' ').first : null;

    if (widget.epaper == null && ep != null && _controller == null && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEpaper(ep));
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis), if (date != null) Text(date, style: Theme.of(context).textTheme.bodySmall)]),
          actions: [if (_pageCount > 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Center(child: Text('$_currentPage / $_pageCount'))), IconButton(icon: const Icon(Icons.share), onPressed: () {})],
        ),
        body: _buildBody(ep),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildBody(Epaper? currentEpaper) {
    if (_loading) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text('${(_progress * 100).toStringAsFixed(0)}%')]));
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Failed to load PDF: $_error'), const SizedBox(height: 12), ElevatedButton(onPressed: () => _openEpaper(currentEpaper), child: const Text('Retry'))]));
    if (_controller == null) return const Center(child: Text('No PDF loaded'));

    return Stack(children: [
      PdfViewPinch(controller: _controller!, onDocumentLoaded: (doc) => setState(() => _pageCount = doc.pagesCount), onPageChanged: (page) => setState(() => _currentPage = page)),
      Positioned(bottom: 18, left: 12, right: 12, child: Center(child: Card(color: Colors.black54, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('$_currentPage / $_pageCount', style: const TextStyle(color: Colors.white))))))
    ]);
  }

  Widget? _buildFab() {
    if (_controller == null) return null;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      FloatingActionButton.small(onPressed: () => _controller?.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.ease), heroTag: 'prev_page', child: const Icon(Icons.chevron_left)),
      const SizedBox(height: 8),
      FloatingActionButton.small(onPressed: () => _controller?.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.ease), heroTag: 'next_page', child: const Icon(Icons.chevron_right)),
    ]);
  }
}
