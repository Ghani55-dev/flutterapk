import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/epaper_providers.dart';
import 'package:pdfx/pdfx.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class EpaperDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const EpaperDetailScreen({super.key, required this.id});

  @override
  ConsumerState<EpaperDetailScreen> createState() => _EpaperDetailScreenState();
}

class _EpaperDetailScreenState extends ConsumerState<EpaperDetailScreen> {
  bool loadingFile = false;
  PdfControllerPinch? controller;
  int currentPage = 1;
  int pageCount = 0;
  String? cachedPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(epaperNotifierProvider.notifier).loadDetail(widget.id));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _downloadAndCache(String url) async {
    setState(() => loadingFile = true);
    try {
      if (url.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No PDF URL available')));
        if (kDebugMode) debugPrint('[EPAPER FAILED] no url');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.id}.pdf');

      // reuse cache if present
      if (await file.exists()) {
        if (kDebugMode) debugPrint('[EPAPER CACHE] using cached file=${file.path}');
        try {
          cachedPath = file.path;
          final futureDoc = PdfDocument.openFile(file.path);
          controller = PdfControllerPinch(document: futureDoc);
          final doc = await futureDoc;
          pageCount = doc.pagesCount;
          setState(() {});
          if (kDebugMode) debugPrint('[EPAPER OPEN] cached=${file.path}');
          return;
        } catch (e) {
          if (kDebugMode) debugPrint('[EPAPER FAILED] cached open failed, will redownload: $e');
          // fall through to re-download
        }
      }

      if (kDebugMode) debugPrint('[EPAPER DOWNLOAD] url=$url');
      final dio = Dio();
      dio.options.receiveTimeout = const Duration(seconds: 15);
      dio.options.connectTimeout = const Duration(seconds: 10);

      Response<List<int>> resp;
      try {
        resp = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
      } on DioException catch (de) {
        if (kDebugMode) debugPrint('[EPAPER DOWNLOAD] dio error ${de.response?.statusCode} ${de.message}');
        // if signed URL expired (403/401), refresh detail and retry once
        final status = de.response?.statusCode;
        if (status == 403 || status == 401) {
          if (kDebugMode) debugPrint('[EPAPER DOWNLOAD] signed URL might have expired. refreshing detail and retrying');
          await ref.read(epaperNotifierProvider.notifier).loadDetail(widget.id);
          final fresh = ref.read(epaperNotifierProvider).selected?.pdfUrl ?? '';
          if (fresh.isNotEmpty && fresh != url) {
            if (kDebugMode) debugPrint('[EPAPER DOWNLOAD] retrying with fresh url=$fresh');
            resp = await dio.get<List<int>>(fresh, options: Options(responseType: ResponseType.bytes));
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (resp.statusCode != 200) throw Exception('Download failed status=${resp.statusCode}');
      await file.writeAsBytes(Uint8List.fromList(resp.data ?? []), flush: true);
      cachedPath = file.path;
      final futureDoc = PdfDocument.openFile(file.path);
      controller = PdfControllerPinch(document: futureDoc);
      final doc = await futureDoc;
      pageCount = doc.pagesCount;
      if (kDebugMode) debugPrint('[EPAPER OPEN] cached=${file.path}');
      setState(() {});
    } catch (e) {
      if (kDebugMode) debugPrint('[OPEN FAILED] $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load PDF: $e')));
      // Try external fallback
      try {
        final uri = Uri.parse(ref.read(epaperNotifierProvider).selected?.pdfUrl ?? '');
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    setState(() => loadingFile = false);
  }

  Future<void> _sharePdf() async {
    if (cachedPath == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please download the PDF first')));
      return;
    }
    await Share.shareXFiles([XFile(cachedPath!)], text: 'E-Paper: ${ref.read(epaperNotifierProvider).selected?.title ?? ''}');
  }

  Future<void> _openExternal() async {
    final url = ref.read(epaperNotifierProvider).selected?.pdfUrl;
    if (url == null || url.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No external URL available')));
      if (kDebugMode) debugPrint('[OPEN FAILED] no url for external open');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (kDebugMode) debugPrint(ok ? '[OPEN SUCCESS] external' : '[OPEN FAILED] external');
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open external URL')));
      if (kDebugMode) debugPrint('[OPEN FAILED] cannot launch external url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(epaperNotifierProvider);
    final e = state.selected;
    return Scaffold(
      appBar: AppBar(title: Text(e?.title ?? 'E-Paper'), actions: [
        IconButton(onPressed: _sharePdf, icon: const Icon(Icons.share)),
        IconButton(onPressed: _openExternal, icon: const Icon(Icons.open_in_new)),
      ]),
      body: e == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (e.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: e.thumbnailUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 160, color: Theme.of(context).colorScheme.surfaceVariant),
                  errorWidget: (_, __, ___) => Container(height: 160, color: Theme.of(context).colorScheme.surfaceVariant, child: const Icon(Icons.picture_as_pdf)),
                ),
              Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: Text(e.title, style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () async { await _downloadAndCache(e.pdfUrl); }, icon: const Icon(Icons.download))])),
              Expanded(
                child: loadingFile
                    ? const Center(child: CircularProgressIndicator())
                    : controller == null
                        ? Center(child: ElevatedButton(onPressed: () async => await _downloadAndCache(e.pdfUrl), child: const Text('Download & Open')))
                        : Stack(children: [
                            PdfViewPinch(
                              controller: controller!,
                              onDocumentLoaded: (doc) => setState(() => pageCount = doc.pagesCount),
                              onPageChanged: (page) => setState(() => currentPage = page),
                            ),
                            Positioned(bottom: 12, left: 12, right: 12, child: Card(color: Theme.of(context).colorScheme.surface.withAlpha((0.9 * 255).round()), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('$currentPage / $pageCount'),
                              Row(children: [IconButton(onPressed: () => controller?.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.ease), icon: const Icon(Icons.chevron_left)), IconButton(onPressed: () => controller?.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.ease), icon: const Icon(Icons.chevron_right))])
                            ])))),
                          ]),
              ),
            ]),
    );
  }
}
