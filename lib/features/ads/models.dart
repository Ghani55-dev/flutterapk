import 'package:flutter/foundation.dart';

class AdItem {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final String zone;
  final int displayFrequency; // insert after N items

  AdItem({required this.id, required this.title, required this.imageUrl, required this.targetUrl, required this.zone, this.displayFrequency = 5});

  factory AdItem.fromJson(Map<String, dynamic> json) {
    final map = json;
    try {
      return AdItem(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? map['headline']?.toString() ?? 'Sponsored',
        imageUrl: map['image_url']?.toString() ?? map['image']?.toString() ?? '',
        targetUrl: map['target_url']?.toString() ?? map['url']?.toString() ?? '',
        zone: map['zone']?.toString() ?? 'feed',
        displayFrequency: map['display_frequency'] != null ? int.tryParse(map['display_frequency'].toString()) ?? 5 : 5,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AdItem.fromJson] parse error: $e');
        debugPrint(st.toString());
        debugPrint('payload: ${map.toString()}');
      }
      return AdItem(id: '', title: 'Sponsored', imageUrl: '', targetUrl: '', zone: 'feed');
    }
  }
}
