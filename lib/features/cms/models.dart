import 'package:flutter/foundation.dart';

class CmsPage {
  final String id;
  final String slug;
  final String title;
  final String content;

  CmsPage({required this.id, required this.slug, required this.title, required this.content});

  factory CmsPage.fromJson(Map<String, dynamic> j) {
    final map = j is Map<String, dynamic> ? j : <String, dynamic>{};
    try {
      return CmsPage(
        id: map['id']?.toString() ?? '',
        slug: map['slug']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        content: map['content']?.toString() ?? map['body']?.toString() ?? '',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CmsPage.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return CmsPage(id: '', slug: '', title: '', content: '');
    }
  }
}
