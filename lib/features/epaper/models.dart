import 'package:flutter/foundation.dart';

class Epaper {
  final String id;
  final String title;
  final String pdfUrl;
  final DateTime? publishedAt;
  final String? thumbnailUrl;

  Epaper({required this.id, required this.title, required this.pdfUrl, this.publishedAt, this.thumbnailUrl});

  factory Epaper.fromJson(Map<String, dynamic> j) {
    final map = j is Map<String, dynamic> ? j : <String, dynamic>{};
    try {
      if (kDebugMode) debugPrint('[EPAPER MODEL] parsing map keys=${map.keys.toList()}');
      return Epaper(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? map['name']?.toString() ?? '',
        pdfUrl: map['pdf_url']?.toString() ?? map['file']?.toString() ?? '',
        publishedAt: map['published_at'] != null
            ? DateTime.tryParse(map['published_at'].toString())
            : (map['edition_date'] != null ? DateTime.tryParse(map['edition_date'].toString()) : null),
        thumbnailUrl: map['thumbnail_url']?.toString() ?? map['thumbnail']?.toString() ?? map['image']?.toString(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Epaper.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return Epaper(id: '', title: '', pdfUrl: '');
    }
  }
}
