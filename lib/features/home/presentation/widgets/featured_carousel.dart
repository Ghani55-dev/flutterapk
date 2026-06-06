import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeaturedCarousel extends StatelessWidget {
  final List<Article> items;
  final ValueChanged<int>? onPageChanged;
  const FeaturedCarousel({super.key, required this.items, this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: items.length,
        onPageChanged: onPageChanged,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          final a = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (a.imageUrl != null)
                    CachedNetworkImage(imageUrl: a.imageUrl!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey[300]))
                  else
                    Container(color: Colors.grey[300]),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
