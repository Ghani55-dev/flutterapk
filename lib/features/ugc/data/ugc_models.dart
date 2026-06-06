class UGCReportItem {
  final String id;
  final String title;
  final String description;
  final String reporterName;
  final String trustLevel;
  final String? location;
  final String? mediaUrl;
  final String contentType;
  final DateTime? createdAt;

  const UGCReportItem({
    required this.id,
    required this.title,
    required this.description,
    required this.reporterName,
    required this.trustLevel,
    this.location,
    this.mediaUrl,
    this.contentType = 'text',
    this.createdAt,
  });

  factory UGCReportItem.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] is Map ? Map<String, dynamic>.from(json['reporter'] as Map) : <String, dynamic>{};
    final location = json['location'] is Map ? Map<String, dynamic>.from(json['location'] as Map) : <String, dynamic>{};
    return UGCReportItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Community report',
      description: json['description']?.toString() ?? json['content']?.toString() ?? '',
      reporterName: reporter['full_name']?.toString() ?? reporter['name']?.toString() ?? json['reporter_name']?.toString() ?? 'VARADHI Reporter',
      trustLevel: reporter['trust_level']?.toString() ?? json['trust_level']?.toString() ?? 'New',
      location: json['location_name']?.toString() ??
          [
            location['village'],
            location['city'],
            location['district'],
            location['state'],
          ].where((part) => part != null && part.toString().isNotEmpty).join(', '),
      mediaUrl: json['media_url']?.toString() ?? json['thumbnail_url']?.toString() ?? json['image_url']?.toString(),
      contentType: json['content_type']?.toString() ?? 'text',
      createdAt: DateTime.tryParse((json['created_at'] ?? json['submitted_at'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'reporter_name': reporterName,
        'trust_level': trustLevel,
        'location_name': location,
        'media_url': mediaUrl,
        'content_type': contentType,
        'created_at': createdAt?.toIso8601String(),
      };
}

class UGCFeedPage {
  final List<UGCReportItem> items;
  final String? nextCursor;

  const UGCFeedPage({required this.items, this.nextCursor});

  factory UGCFeedPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    final rawItems = data['results'] ?? data['items'] ?? data['reports'] ?? data['data'] ?? [];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((item) => UGCReportItem.fromJson(Map<String, dynamic>.from(item))).where((item) => item.id.isNotEmpty).toList()
        : <UGCReportItem>[];
    return UGCFeedPage(items: items, nextCursor: _parseCursor(data['next_cursor'] ?? data['cursor'] ?? data['next']));
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

class UGCMediaUpload {
  final String id;
  final String status;
  final String? url;

  const UGCMediaUpload({required this.id, required this.status, this.url});

  factory UGCMediaUpload.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    return UGCMediaUpload(
      id: data['id']?.toString() ?? data['media_id']?.toString() ?? '',
      status: data['status']?.toString().toUpperCase() ?? 'PROCESSING',
      url: data['url']?.toString() ?? data['media_url']?.toString(),
    );
  }
}

class UGCSubmissionResult {
  final String id;
  final String status;
  final bool flaggedForReview;

  const UGCSubmissionResult({required this.id, required this.status, required this.flaggedForReview});

  factory UGCSubmissionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    final status = data['status']?.toString().toUpperCase() ?? 'UNDER_REVIEW';
    final flagged = data['flagged_for_review'] == true || status.contains('FLAG');
    return UGCSubmissionResult(
      id: data['id']?.toString() ?? '',
      status: status,
      flaggedForReview: flagged,
    );
  }
}
