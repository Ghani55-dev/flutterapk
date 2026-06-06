import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models.dart';

class EpaperCard extends StatelessWidget {
  final Epaper epaper;
  final VoidCallback? onTap;
  const EpaperCard({super.key, required this.epaper, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: epaper.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: epaper.thumbnailUrl!,
                width: 64,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 64, color: Theme.of(context).colorScheme.surfaceVariant),
                errorWidget: (_, __, ___) => Icon(Icons.picture_as_pdf, size: 40, color: Theme.of(context).colorScheme.primary),
              )
            : Icon(Icons.picture_as_pdf, size: 40, color: Theme.of(context).colorScheme.primary),
        title: Text(epaper.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(epaper.publishedAt != null ? epaper.publishedAt!.toLocal().toString().split(' ').first : ''),
        onTap: () {
          try {
            if (kDebugMode) debugPrint('[EPAPER TAP] id=${epaper.id} title=${epaper.title}');
          } catch (_) {}
          if (onTap != null) onTap!();
        },
        trailing: const Icon(Icons.open_in_new),
      ),
    );
  }
}
