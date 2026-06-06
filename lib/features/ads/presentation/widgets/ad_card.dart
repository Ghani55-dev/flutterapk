import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../ads/models.dart';
import '../../../../providers/ads_providers.dart';

class AdCard extends ConsumerStatefulWidget {
  final AdItem ad;
  const AdCard({super.key, required this.ad});

  @override
  ConsumerState<AdCard> createState() => _AdCardState();
}

class _AdCardState extends ConsumerState<AdCard> {
  String? _trackedAdId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackImpressionOnce());
  }

  @override
  void didUpdateWidget(covariant AdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.id != widget.ad.id) {
      _trackedAdId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _trackImpressionOnce());
    }
  }

  void _trackImpressionOnce() {
    if (!mounted || _trackedAdId == widget.ad.id) return;
    _trackedAdId = widget.ad.id;
    ref.read(adsRepositoryProvider).trackImpression(widget.ad.id);
  }

  Future<void> _onTap() async {
    final repo = ref.read(adsRepositoryProvider);
    // track click then open
    await repo.trackClick(widget.ad.id, widget.ad.targetUrl);
    final uri = Uri.tryParse(widget.ad.targetUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ad.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
                errorWidget: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(Icons.campaign_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: Text(ad.title, style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _onTap, child: const Text('Open'))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 12.0),
            child: Text('Sponsored', style: Theme.of(context).textTheme.labelSmall),
          )
        ],
      ),
    );
  }
}
