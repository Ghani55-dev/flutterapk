import 'package:flutter/foundation.dart';

class Article {
  final String id;
  final String slug;
  final String title;
  final String? excerpt;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String? categoryId;
  final String? categoryName;

  Article({
    required this.id,
    required this.slug,
    required this.title,
    this.excerpt,
    this.imageUrl,
    this.publishedAt,
    this.categoryId,
    this.categoryName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final map = json;
    final category = map['category'] is Map ? Map<String, dynamic>.from(map['category']) : <String, dynamic>{};

    try {
      final rawImage = map['image_url'] ?? map['thumbnail_url'] ?? map['hero_image'] ?? map['thumbnail'];
      final imageUrl = rawImage is String ? rawImage : (rawImage?.toString());

      return Article(
        id: map['id']?.toString() ?? '',
        slug: map['slug']?.toString() ?? map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        excerpt: map['excerpt']?.toString() ?? map['summary']?.toString() ?? map['description']?.toString(),
        imageUrl: imageUrl,
        publishedAt: map['published_at'] != null ? DateTime.tryParse(map['published_at'].toString()) : null,
        categoryId: map['category_id'] != null ? map['category_id'].toString() : (category['id']?.toString()),
        categoryName: map['category_name']?.toString() ?? category['name']?.toString(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Article.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${json.toString()}');
      }
      return Article(id: '', slug: '', title: '');
    }
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? slug;

  CategoryModel({required this.id, required this.name, this.slug});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final map = json;
    try {
      return CategoryModel(
        id: map['id']?.toString() ?? '',
        name: map['display_name']?.toString() ?? map['name']?.toString() ?? map['title']?.toString() ?? '',
        slug: map['slug']?.toString(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CategoryModel.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return CategoryModel(id: '', name: '');
    }
  }
}

class PaginatedArticles {
  final List<Article> results;
  final int page;
  final int pageSize;
  final int? total;

  PaginatedArticles({required this.results, required this.page, required this.pageSize, this.total});

  factory PaginatedArticles.fromJson(Map<String, dynamic> json) {
    final map = json;
    dynamic data = map['data'] ?? map;

    try {
      // If data is a top-level list
      if (data is List) {
        final List<Article> items = List<dynamic>.from(data).map((e) {
          if (e is Map) return Article.fromJson(Map<String, dynamic>.from(e));
          return Article.fromJson(<String, dynamic>{});
        }).toList();
        return PaginatedArticles(results: items, page: 1, pageSize: items.length, total: items.length);
      }

        // data expected to be Map
        final Map<String, dynamic> dataMap = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        final resultsRaw = dataMap['results'] ?? dataMap['items'] ?? dataMap['articles'] ?? dataMap['data'] ?? [];
        final List<Article> items = (resultsRaw is List)
          ? List<dynamic>.from(resultsRaw).map((e) => e is Map ? Article.fromJson(Map<String, dynamic>.from(e)) : Article.fromJson(<String, dynamic>{})).toList()
          : <Article>[];

      int parseInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is String) return int.tryParse(v) ?? 0;
        return 0;
      }

      final page = parseInt(dataMap['page'] ?? dataMap['current_page'] ?? 1);
      final pageSize = parseInt(dataMap['page_size'] ?? dataMap['per_page'] ?? items.length);
      final total = dataMap['total'] != null ? parseInt(dataMap['total']) : null;
      return PaginatedArticles(results: items, page: page, pageSize: pageSize, total: total);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PaginatedArticles.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${json.toString()}');
      }
      return PaginatedArticles(results: [], page: 1, pageSize: 0);
    }
  }
}
