import 'dart:convert';
import '../../home/data/models.dart';
import '../../../core/storage/secure_storage_interface.dart';

class HistoryRepository {
  final SecureStorageInterface storage;
  static const _key = 'reading_history';
  HistoryRepository({required this.storage});

  Future<List<Map<String, dynamic>>> _readRaw() async {
    final s = await storage.read(_key);
    if (s == null) return [];
    try {
      final j = json.decode(s);
      if (j is List) return j.map((e) => Map<String, dynamic>.from(e)).toList();
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeRaw(List<Map<String, dynamic>> data) async {
    await storage.write(_key, json.encode(data));
  }

  Future<void> add(Article article) async {
    final raw = await _readRaw();
    final now = DateTime.now().toIso8601String();
    // store minimal article + timestamp
    final entry = {'id': article.id, 'slug': article.slug, 'title': article.title, 'excerpt': article.excerpt, 'image_url': article.imageUrl, 'published_at': article.publishedAt?.toIso8601String(), 'seen_at': now};
    // ensure uniqueness by slug, place newest first
    raw.removeWhere((e) => e['slug'] == article.slug);
    raw.insert(0, entry);
    // trim to last 200
    if (raw.length > 200) raw.removeRange(200, raw.length);
    await _writeRaw(raw);
  }

  Future<List<Map<String, dynamic>>> list() async => await _readRaw();

  Future<void> clear() async => await _writeRaw([]);
}
