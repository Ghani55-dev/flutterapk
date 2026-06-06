import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../reels/models.dart';
import 'data/video_repository.dart';
import 'video_playback_manager.dart';
import '../location/location_provider.dart';

class ReelsState {
  final List<VideoItem> items;
  final int currentIndex;
  final bool isLoading;

  ReelsState({this.items = const [], this.currentIndex = 0, this.isLoading = false});

  ReelsState copyWith({List<VideoItem>? items, int? currentIndex, bool? isLoading}) =>
      ReelsState(items: items ?? this.items, currentIndex: currentIndex ?? this.currentIndex, isLoading: isLoading ?? this.isLoading);
}

class ReelsNotifier extends StateNotifier<ReelsState> {
  final VideoRepository repository;
  final VideoPlaybackManager playbackManager;
  final Ref ref;
  int _page = 1;

  ReelsNotifier({required this.ref, required this.repository, required this.playbackManager}) : super(ReelsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true);
    try {
      final locAv = ref.read(locationProvider);
      Map<String, String>? loc;
      if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      final items = await repository.fetchShorts(
        page: 1,
        state: loc?['state'],
        district: loc?['district'],
        city: loc?['city'],
      );
      state = state.copyWith(items: items, isLoading: false);
      // prewarm first controller
      if (items.isNotEmpty) {
        if (kDebugMode) debugPrint('[Reels] first item url=${items[0].url} youtube=${items[0].isYouTube} id=${items[0].youtubeVideoId}');
        if (!items[0].isYouTube) await playbackManager.createController(0, items[0].url, autoPlay: true, looping: true);
        if (items.length > 1 && !items[1].isYouTube) await playbackManager.createController(1, items[1].url, looping: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Reels load error $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> onPageChanged(int index) async {
    final prev = state.currentIndex;
    state = state.copyWith(currentIndex: index);
    // pause previous
    playbackManager.pause(prev);
    // play current (create if needed)
    final items = state.items;
    if (index < items.length) {
      if (kDebugMode) debugPrint('[Reels] page=$index url=${items[index].url} youtube=${items[index].isYouTube} id=${items[index].youtubeVideoId}');
      if (!items[index].isYouTube) {
        await playbackManager.createController(index, items[index].url, autoPlay: true, looping: true);
      }
      // preload next
      final next = index + 1;
      if (next < items.length && !items[next].isYouTube) await playbackManager.createController(next, items[next].url, looping: true);
    }
    // dispose far-away controllers
    final keys = playbackManager.keys();
    for (final i in keys) {
      if ((i - index).abs() > 2) playbackManager.disposeController(i);
    }
  }

  Future<void> fetchMore() async {
    _page += 1;
    try {
      final locAv = ref.read(locationProvider);
      Map<String, String>? loc;
      if (locAv is AsyncData<Map<String, String>?>) loc = locAv.value;
      final more = await repository.fetchShorts(page: _page, state: loc?['state'], district: loc?['district'], city: loc?['city']);
      final combined = List<VideoItem>.from(state.items)..addAll(more);
      state = state.copyWith(items: combined);
    } catch (e) {
      if (kDebugMode) debugPrint('Reels fetchMore error $e');
    }
  }

  @override
  void dispose() {
    playbackManager.disposeAll();
    super.dispose();
  }
}
