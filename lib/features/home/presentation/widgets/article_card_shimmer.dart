import 'package:flutter/material.dart';
import 'shimmer.dart';

class ArticleCardShimmer extends StatelessWidget {
  const ArticleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const ShimmerPlaceholder(width: 100, height: 72),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerPlaceholder(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  ShimmerPlaceholder(width: double.infinity, height: 12),
                  SizedBox(height: 12),
                  ShimmerPlaceholder(width: 80, height: 12),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
