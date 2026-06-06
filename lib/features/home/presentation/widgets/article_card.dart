import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models.dart';
import '../../../article/presentation/article_detail_screen.dart';
import '../../../../core/utils/freshness.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback? onTap;
  const ArticleCard({super.key, required this.article, this.onTap});

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _navigating = false;

  void _handleTap() {
    if (_navigating) return;
    _navigating = true;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: widget.article.slug))).whenComplete(() {
      // restore flag after navigation returns
      _navigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return GestureDetector(
      onTap: widget.onTap ?? _handleTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (article.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Hero(
                    tag: 'article-${article.slug}',
                    child: CachedNetworkImage(
                      imageUrl: article.imageUrl ?? '',
                      width: 100,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (c, s) => Container(color: Colors.grey[300], width: 100, height: 72),
                      errorWidget: (c, s, e) => Container(color: Colors.grey[300], width: 100, height: 72),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    if (article.excerpt != null)
                      Text(article.excerpt ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (article.categoryName != null)
                          Text(article.categoryName!, style: Theme.of(context).textTheme.labelSmall),
                        const Spacer(),
                        if (article.publishedAt != null) ...[
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(6)), child: Text(formatFreshnessTag(article.publishedAt), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800))),
                          const SizedBox(width: 6),
                          Text(article.publishedAt!.toLocal().toString().split(' ').first, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
