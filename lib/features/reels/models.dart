import 'package:flutter/foundation.dart';

class VideoItem {
  final String id;
  final String title;
  final String url;
  final String? thumbnail;
  final int? durationSeconds;
  final bool isYouTube;
  final String? youtubeVideoId;
  final String? sourceName;
  final DateTime? publishedAt;

  VideoItem({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnail,
    this.durationSeconds,
    this.isYouTube = false,
    this.youtubeVideoId,
    this.sourceName,
    this.publishedAt,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    final map = json;

    String safePreview(Map<String, dynamic> m) {
      final s = m.toString();
      return s.length > 200 ? s.substring(0, 200) : s;
    }

    try {
      final youtubeUrl = map['youtube_url']?.toString();
      final youtubeVideoId = map['youtube_video_id']?.toString();
      final rawUrl = map['video_url']?.toString() ?? map['url']?.toString() ?? youtubeUrl ?? '';
      final isYouTube = (map['is_youtube'] == true) ||
          (map['video_provider']?.toString() == 'youtube') ||
          youtubeVideoId != null ||
          rawUrl.contains('youtube.com') ||
          rawUrl.contains('youtu.be');
      return VideoItem(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        url: rawUrl,
        thumbnail: map['thumbnail_url']?.toString() ?? map['thumbnail']?.toString() ?? map['image']?.toString(),
        durationSeconds: map['duration_seconds'] != null ? int.tryParse(map['duration_seconds'].toString()) : null,
        isYouTube: isYouTube,
        youtubeVideoId: youtubeVideoId,
        sourceName: map['source_name']?.toString() ?? map['channel_name']?.toString() ?? map['channel']?.toString(),
        publishedAt: map['published_at'] != null ? DateTime.tryParse(map['published_at'].toString()) : null,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[VideoItem.fromJson] parse error: $e');
        debugPrint('[VideoItem.fromJson] payload preview: ${safePreview(map)}');
        debugPrint(st.toString());
      }
      return VideoItem(id: '', title: '', url: '');
    }
  }
}
