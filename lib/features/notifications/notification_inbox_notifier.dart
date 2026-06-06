import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/notification_models.dart';
import 'data/notification_repository.dart';

class NotificationInboxState {
  final List<NotificationInboxItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final bool offline;
  final bool showingCachedData;
  final String? nextCursor;
  final String? error;
  final int unreadCount;

  const NotificationInboxState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.offline = false,
    this.showingCachedData = false,
    this.nextCursor,
    this.error,
    this.unreadCount = 0,
  });

  NotificationInboxState copyWith({
    List<NotificationInboxItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    bool? offline,
    bool? showingCachedData,
    String? nextCursor,
    bool clearNextCursor = false,
    String? error,
    int? unreadCount,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offline: offline ?? this.offline,
      showingCachedData: showingCachedData ?? this.showingCachedData,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationInboxNotifier extends StateNotifier<NotificationInboxState> {
  final NotificationRepository repository;

  NotificationInboxNotifier({required this.repository}) : super(const NotificationInboxState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null, clearNextCursor: true);
    await _loadUnreadCount();
    try {
      final page = await repository.fetchInbox();
      state = state.copyWith(
        items: page.items,
        isLoading: false,
        hasMore: page.nextCursor != null,
        nextCursor: page.nextCursor,
        offline: false,
        showingCachedData: false,
      );
    } catch (error) {
      await _restoreCacheOrError(error);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null, clearNextCursor: true);
    await _loadUnreadCount();
    try {
      final page = await repository.fetchInbox();
      state = state.copyWith(
        items: page.items,
        isRefreshing: false,
        hasMore: page.nextCursor != null,
        nextCursor: page.nextCursor,
        offline: false,
        showingCachedData: false,
      );
    } catch (error) {
      await _restoreCacheOrError(error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isRefreshing || state.isLoadingMore || !state.hasMore || state.nextCursor == null) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final page = await repository.fetchInbox(cursor: state.nextCursor);
      final merged = <NotificationInboxItem>[...state.items, ...page.items];
      state = state.copyWith(
        items: merged,
        isLoadingMore: false,
        hasMore: page.nextCursor != null,
        nextCursor: page.nextCursor,
        offline: false,
        showingCachedData: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        offline: repository.isNetworkError(error),
        showingCachedData: state.items.isNotEmpty && repository.isNetworkError(error),
        error: state.items.isNotEmpty && repository.isNetworkError(error) ? null : error.toString(),
      );
    }
  }

  Future<NotificationInboxItem?> openNotification(NotificationInboxItem item) async {
    if (!item.isRead) {
      await markRead(item.id);
    }
    try {
      return await repository.fetchNotification(item.id);
    } catch (_) {
      return item.copyWith(isRead: true);
    }
  }

  Future<void> markRead(String id) async {
    final previousUnread = state.unreadCount;
    final updatedItems = state.items.map((item) => item.id == id ? item.copyWith(isRead: true) : item).toList();
    state = state.copyWith(items: updatedItems, unreadCount: previousUnread > 0 ? previousUnread - 1 : 0);
    try {
      await repository.markRead(id);
      await _loadUnreadCount();
    } catch (_) {
      state = state.copyWith(unreadCount: previousUnread);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await repository.fetchUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  Future<void> _restoreCacheOrError(Object error) async {
    final networkError = repository.isNetworkError(error);
    if (networkError) {
      final cached = await repository.getCachedInbox();
      if (cached != null && cached.items.isNotEmpty) {
        state = state.copyWith(
          items: cached.items,
          isLoading: false,
          isRefreshing: false,
          hasMore: false,
          offline: true,
          showingCachedData: true,
          error: null,
          clearNextCursor: true,
        );
        return;
      }
    }

    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      offline: networkError,
      showingCachedData: false,
      error: error.toString(),
    );
  }
}
