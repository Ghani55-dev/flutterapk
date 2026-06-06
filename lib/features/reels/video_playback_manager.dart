import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoPlaybackManager {
  final Map<int, VideoPlayerController> _controllers = {};

  Future<VideoPlayerController> createController(int index, String url, {bool autoPlay = false, bool looping = false}) async {
    if (_controllers.containsKey(index)) return _controllers[index]!;
    if (url.trim().isEmpty) {
      throw ArgumentError('Empty reels video URL at index $index');
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      throw ArgumentError('YouTube URL requires YoutubePlayer, not video_player: $url');
    }
    if (kDebugMode) debugPrint('[ReelsPlayer] create index=$index url=$url autoPlay=$autoPlay');
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = controller;
    controller.addListener(() {
      if (kDebugMode) {
        final v = controller.value;
        if (v.hasError) {
          debugPrint('[ReelsPlayer] error index=$index initialized=${v.isInitialized} playing=${v.isPlaying} error=${v.errorDescription}');
        }
      }
    });
    await controller.initialize();
    if (kDebugMode) {
      final v = controller.value;
      debugPrint('[ReelsPlayer] initialized index=$index initialized=${v.isInitialized} size=${v.size} duration=${v.duration}');
    }
    controller.setLooping(looping);
    if (autoPlay) {
      await controller.play();
      if (kDebugMode) debugPrint('[ReelsPlayer] play index=$index isPlaying=${controller.value.isPlaying}');
    }
    return controller;
  }

  VideoPlayerController? controllerFor(int index) => _controllers[index];

  void play(int index) {
    final c = _controllers[index];
    if (c != null && !c.value.isPlaying) {
      c.play();
      if (kDebugMode) debugPrint('[ReelsPlayer] resume index=$index isPlaying=${c.value.isPlaying}');
    }
  }

  void pause(int index) {
    final c = _controllers[index];
    if (c != null && c.value.isPlaying) c.pause();
  }

  void disposeController(int index) {
    final c = _controllers.remove(index);
    c?.dispose();
  }

  void disposeAll() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  // Return current controller indices
  List<int> keys() => _controllers.keys.toList();

  // Prune controllers that are farther than [radius] from [center]
  void pruneExceptAround(int center, {int radius = 2}) {
    final toRemove = _controllers.keys.where((i) => (i - center).abs() > radius).toList();
    for (final i in toRemove) {
      disposeController(i);
    }
  }
}
