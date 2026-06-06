import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/ugc_models.dart';
import 'data/ugc_repository.dart';

class UGCState {
  final List<UGCReportItem> feedItems;
  final bool feedLoading;
  final bool feedRefreshing;
  final bool feedLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final bool offline;
  final bool showingCachedData;
  final String? feedError;
  final bool otpSending;
  final bool otpVerifying;
  final bool otpVerified;
  final int resendCooldown;
  final String? otpError;
  final double uploadProgress;
  final String uploadStatus;
  final List<String> mediaIds;
  final String? uploadError;
  final bool submitting;
  final UGCSubmissionResult? submissionResult;
  final String? submissionError;
  final bool reportSubmitting;
  final String? reportSuccessId;
  final String? reportError;

  const UGCState({
    this.feedItems = const [],
    this.feedLoading = false,
    this.feedRefreshing = false,
    this.feedLoadingMore = false,
    this.hasMore = true,
    this.nextCursor,
    this.offline = false,
    this.showingCachedData = false,
    this.feedError,
    this.otpSending = false,
    this.otpVerifying = false,
    this.otpVerified = false,
    this.resendCooldown = 0,
    this.otpError,
    this.uploadProgress = 0,
    this.uploadStatus = 'READY',
    this.mediaIds = const [],
    this.uploadError,
    this.submitting = false,
    this.submissionResult,
    this.submissionError,
    this.reportSubmitting = false,
    this.reportSuccessId,
    this.reportError,
  });

  UGCState copyWith({
    List<UGCReportItem>? feedItems,
    bool? feedLoading,
    bool? feedRefreshing,
    bool? feedLoadingMore,
    bool? hasMore,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? offline,
    bool? showingCachedData,
    String? feedError,
    bool? otpSending,
    bool? otpVerifying,
    bool? otpVerified,
    int? resendCooldown,
    String? otpError,
    double? uploadProgress,
    String? uploadStatus,
    List<String>? mediaIds,
    String? uploadError,
    bool? submitting,
    UGCSubmissionResult? submissionResult,
    bool clearSubmissionResult = false,
    String? submissionError,
    bool? reportSubmitting,
    String? reportSuccessId,
    String? reportError,
  }) {
    return UGCState(
      feedItems: feedItems ?? this.feedItems,
      feedLoading: feedLoading ?? this.feedLoading,
      feedRefreshing: feedRefreshing ?? this.feedRefreshing,
      feedLoadingMore: feedLoadingMore ?? this.feedLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      offline: offline ?? this.offline,
      showingCachedData: showingCachedData ?? this.showingCachedData,
      feedError: feedError,
      otpSending: otpSending ?? this.otpSending,
      otpVerifying: otpVerifying ?? this.otpVerifying,
      otpVerified: otpVerified ?? this.otpVerified,
      resendCooldown: resendCooldown ?? this.resendCooldown,
      otpError: otpError,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      mediaIds: mediaIds ?? this.mediaIds,
      uploadError: uploadError,
      submitting: submitting ?? this.submitting,
      submissionResult: clearSubmissionResult ? null : submissionResult ?? this.submissionResult,
      submissionError: submissionError,
      reportSubmitting: reportSubmitting ?? this.reportSubmitting,
      reportSuccessId: reportSuccessId,
      reportError: reportError,
    );
  }
}

class UGCNotifier extends StateNotifier<UGCState> {
  final UGCRepository repository;
  Timer? _cooldownTimer;

  UGCNotifier({required this.repository}) : super(const UGCState()) {
    loadFeed();
  }

  Future<void> sendOtp(String phone) async {
    if (state.resendCooldown > 0) return;
    state = state.copyWith(otpSending: true, otpError: null);
    try {
      await repository.sendOtp(phone: phone);
      state = state.copyWith(otpSending: false, resendCooldown: 45);
      _startCooldown();
    } catch (error) {
      state = state.copyWith(otpSending: false, otpError: error.toString());
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = state.copyWith(otpVerifying: true, otpError: null);
    try {
      await repository.verifyOtp(phone: phone, otp: otp);
      state = state.copyWith(otpVerifying: false, otpVerified: true);
      return true;
    } catch (error) {
      state = state.copyWith(otpVerifying: false, otpError: error.toString());
      return false;
    }
  }

  Future<void> uploadMedia({required String filePath, required String contentType}) async {
    state = state.copyWith(uploadProgress: 0, uploadStatus: 'PROCESSING', uploadError: null);
    try {
      final upload = await repository.uploadMedia(
        filePath: filePath,
        contentType: contentType,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          state = state.copyWith(uploadProgress: sent / total);
        },
      );
      final nextIds = upload.id.isEmpty ? state.mediaIds : <String>[...state.mediaIds, upload.id];
      state = state.copyWith(uploadProgress: 1, uploadStatus: upload.status, mediaIds: nextIds);
    } catch (error) {
      state = state.copyWith(uploadStatus: 'FAILED', uploadError: error.toString());
    }
  }

  Future<UGCSubmissionResult?> submit({
    required String title,
    required String description,
    required String category,
    required Map<String, String> location,
    required String contentType,
  }) async {
    state = state.copyWith(submitting: true, submissionError: null, clearSubmissionResult: true);
    try {
      final result = await repository.submit(
        title: title,
        description: description,
        category: category,
        location: location,
        contentType: contentType,
        mediaIds: state.mediaIds,
      );
      state = state.copyWith(submitting: false, submissionResult: result);
      return result;
    } catch (error) {
      state = state.copyWith(submitting: false, submissionError: error.toString());
      return null;
    }
  }

  Future<void> loadFeed() async {
    state = state.copyWith(feedLoading: true, feedError: null, clearNextCursor: true);
    try {
      final page = await repository.fetchFeed();
      state = state.copyWith(
        feedItems: page.items,
        feedLoading: false,
        hasMore: page.nextCursor != null,
        nextCursor: page.nextCursor,
        offline: false,
        showingCachedData: false,
      );
    } catch (error) {
      await _restoreFeedCacheOrError(error);
    }
  }

  Future<void> refreshFeed() async {
    state = state.copyWith(feedRefreshing: true, feedError: null, clearNextCursor: true);
    try {
      final page = await repository.fetchFeed();
      state = state.copyWith(
        feedItems: page.items,
        feedRefreshing: false,
        hasMore: page.nextCursor != null,
        nextCursor: page.nextCursor,
        offline: false,
        showingCachedData: false,
      );
    } catch (error) {
      await _restoreFeedCacheOrError(error);
    }
  }

  Future<void> loadMoreFeed() async {
    if (state.feedLoading || state.feedRefreshing || state.feedLoadingMore || !state.hasMore || state.nextCursor == null) return;
    state = state.copyWith(feedLoadingMore: true, feedError: null);
    try {
      final page = await repository.fetchFeed(cursor: state.nextCursor);
      state = state.copyWith(
        feedItems: [...state.feedItems, ...page.items],
        feedLoadingMore: false,
        hasMore: page.nextCursor != null,
        nextCursor: page.nextCursor,
        offline: false,
        showingCachedData: false,
      );
    } catch (error) {
      final networkError = repository.isNetworkError(error);
      state = state.copyWith(
        feedLoadingMore: false,
        offline: networkError,
        showingCachedData: networkError && state.feedItems.isNotEmpty,
        feedError: networkError && state.feedItems.isNotEmpty ? null : error.toString(),
      );
    }
  }

  Future<bool> reportUGC({required String ugcId, required String reason}) async {
    state = state.copyWith(reportSubmitting: true, reportError: null, reportSuccessId: null);
    try {
      await repository.report(ugcId: ugcId, reason: reason);
      state = state.copyWith(reportSubmitting: false, reportSuccessId: ugcId);
      return true;
    } catch (error) {
      state = state.copyWith(reportSubmitting: false, reportError: error.toString());
      return false;
    }
  }

  Future<void> _restoreFeedCacheOrError(Object error) async {
    final networkError = repository.isNetworkError(error);
    if (networkError) {
      final cached = await repository.getCachedFeed();
      if (cached != null && cached.items.isNotEmpty) {
        state = state.copyWith(
          feedItems: cached.items,
          feedLoading: false,
          feedRefreshing: false,
          hasMore: false,
          offline: true,
          showingCachedData: true,
          feedError: null,
          clearNextCursor: true,
        );
        return;
      }
    }
    state = state.copyWith(feedLoading: false, feedRefreshing: false, offline: networkError, showingCachedData: false, feedError: error.toString());
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.resendCooldown - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(resendCooldown: 0);
      } else {
        state = state.copyWith(resendCooldown: next);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
