class NotificationInboxItem {
  final String id;
  final String title;
  final String body;
  final String? deepLink;
  final DateTime? createdAt;
  final bool isRead;

  const NotificationInboxItem({
    required this.id,
    required this.title,
    required this.body,
    this.deepLink,
    this.createdAt,
    this.isRead = false,
  });

  factory NotificationInboxItem.fromJson(Map<String, dynamic> json) {
    final readValue = json['is_read'] ?? json['read'] ?? json['read_at'];
    return NotificationInboxItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['heading']?.toString() ?? 'VARADHI update',
      body: json['body']?.toString() ?? json['message']?.toString() ?? json['description']?.toString() ?? '',
      deepLink: json['deep_link']?.toString() ?? json['deeplink']?.toString() ?? json['action_url']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['sent_at'] ?? json['published_at']),
      isRead: readValue == true || readValue?.toString().isNotEmpty == true && readValue?.toString() != 'false',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'deep_link': deepLink,
        'created_at': createdAt?.toIso8601String(),
        'is_read': isRead,
      };

  NotificationInboxItem copyWith({bool? isRead}) {
    return NotificationInboxItem(
      id: id,
      title: title,
      body: body,
      deepLink: deepLink,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class NotificationInboxPage {
  final List<NotificationInboxItem> items;
  final String? nextCursor;

  const NotificationInboxPage({required this.items, this.nextCursor});

  factory NotificationInboxPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    final rawItems = data['results'] ?? data['items'] ?? data['notifications'] ?? data['data'] ?? [];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((item) => NotificationInboxItem.fromJson(Map<String, dynamic>.from(item))).where((item) => item.id.isNotEmpty).toList()
        : <NotificationInboxItem>[];
    return NotificationInboxPage(
      items: items,
      nextCursor: _parseCursor(data['next_cursor'] ?? data['cursor'] ?? data['next']),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'results': items.map((item) => item.toJson()).toList(),
          'next_cursor': nextCursor,
        },
      };

  static String? _parseCursor(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.isEmpty || text == 'null') return null;
    final uri = Uri.tryParse(text);
    if (uri != null && uri.queryParameters['cursor']?.isNotEmpty == true) {
      return uri.queryParameters['cursor'];
    }
    return text;
  }
}
