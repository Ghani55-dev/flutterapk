import 'package:flutter/foundation.dart';

class ArticleDetail {
  final String id;
  final String title;
  final String slug;
  final String? summary;
  final String? content;
  final String? thumbnailUrl;
  final String? authorName;
  final String? sourceName;
  final DateTime? publishedAt;
  final int? readTimeMinutes;
  final bool isBookmarked;
  final List<String> tags;
  final String? categorySlug;

  ArticleDetail({required this.id, required this.title, required this.slug, this.summary, this.content, this.thumbnailUrl, this.authorName, this.sourceName, this.publishedAt, this.readTimeMinutes, this.isBookmarked = false, this.tags = const [], this.categorySlug});

  factory ArticleDetail.fromJson(Map<String, dynamic> json) {
    final map = json;
    final authorMap = map['author'] is Map ? Map<String, dynamic>.from(map['author']) : <String, dynamic>{};
    final categoryMap = map['category'] is Map ? Map<String, dynamic>.from(map['category']) : <String, dynamic>{};
    final seoTags = map['seo_tags'] is List ? List<dynamic>.from(map['seo_tags']) : <dynamic>[];

    String safePreview(Map<String, dynamic> m) {
      final s = m.toString();
      return s.length > 200 ? s.substring(0, 200) : s;
    }

    try {
      return ArticleDetail(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        slug: map['slug']?.toString() ?? map['id']?.toString() ?? '',
        summary: map['summary']?.toString() ?? map['excerpt']?.toString(),
        content: map['content']?.toString() ?? map['body']?.toString(),
        thumbnailUrl: map['thumbnail_url']?.toString() ?? map['thumbnail']?.toString(),
        authorName: authorMap['full_name']?.toString() ?? authorMap['name']?.toString() ?? map['author']?.toString(),
        sourceName: map['source_name']?.toString(),
        publishedAt: map['published_at'] != null ? DateTime.tryParse(map['published_at'].toString()) : null,
        readTimeMinutes: map['read_time_minutes'] is int ? map['read_time_minutes'] : (map['read_time'] is int ? map['read_time'] : null),
        isBookmarked: map['is_bookmarked'] == true,
        tags: seoTags.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList(),
        categorySlug: categoryMap['slug']?.toString() ?? map['category_slug']?.toString(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ArticleDetail.fromJson] parse error: $e');
        debugPrint('[ArticleDetail.fromJson] payload preview: ${safePreview(map)}');
        debugPrint(st.toString());
      }
      return ArticleDetail(id: '', title: '', slug: '');
    }
  }
}
