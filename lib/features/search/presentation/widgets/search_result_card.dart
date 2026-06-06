import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../home/data/models.dart';
import '../../../article/presentation/article_detail_screen.dart';

class SearchResultCard extends StatelessWidget {
  final Article article;
  const SearchResultCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: article.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: article.imageUrl!,
              width: 72,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 72, color: Theme.of(context).colorScheme.surfaceVariant),
              errorWidget: (_, __, ___) => Container(width: 72, color: Theme.of(context).colorScheme.surfaceVariant),
            )
          : null,
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [if (article.categoryName != null) Text(article.categoryName!), const SizedBox(width: 8), if (article.publishedAt != null) Text(article.publishedAt!.toLocal().toString().split(' ').first)]),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: article.slug))),
    );
  }
}
