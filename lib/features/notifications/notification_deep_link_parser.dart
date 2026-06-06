class NotificationDeepLinkParser {
  const NotificationDeepLinkParser._();

  static String? routeFor(String? payload) {
    final value = payload?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('/')) return value;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (uri.scheme == 'article' && uri.host.isNotEmpty) {
      return '/article/${Uri.encodeComponent(uri.host)}';
    }
    if (uri.scheme == 'poll' && uri.host.isNotEmpty) {
      return '/polls';
    }
    if (uri.scheme == 'screen') {
      switch (uri.host) {
        case 'feed':
          return '/';
        case 'bookmarks':
          return '/bookmarks';
        case 'community':
          return '/community';
      }
    }

    return null;
  }
}
