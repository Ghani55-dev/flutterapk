import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/data/notification_remote_datasource.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/notification_inbox_notifier.dart';
import 'core_providers.dart';

final notificationRemoteProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(apiClient: ref.read(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    remote: ref.read(notificationRemoteProvider),
    storage: ref.read(secureStorageProvider),
  );
});

final notificationInboxProvider = StateNotifierProvider<NotificationInboxNotifier, NotificationInboxState>((ref) {
  return NotificationInboxNotifier(repository: ref.read(notificationRepositoryProvider));
});

final notificationUnreadCountProvider = FutureProvider<int>((ref) {
  return ref.read(notificationRepositoryProvider).fetchUnreadCount();
});
