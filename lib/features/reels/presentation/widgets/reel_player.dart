import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../providers/reels_providers.dart';

class ReelPlayer extends ConsumerStatefulWidget {
  final int index;
  final String url;
  final String? thumbnail;
  final bool isYouTube;
  final String? youtubeVideoId;
  const ReelPlayer({
    super.key,
    required this.index,
    required this.url,
    this.thumbnail,
    this.isYouTube = false,
    this.youtubeVideoId,
  });

  @override
  ConsumerState<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends ConsumerState<ReelPlayer> {
  VideoPlayerController? _controller;
  YoutubePlayerController? _youtubeController;
  bool _initializing = false;
  String? _error;

  String? get _youtubeId => widget.youtubeVideoId ?? YoutubePlayer.convertUrlToId(widget.url);

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.youtubeVideoId != widget.youtubeVideoId || oldWidget.isYouTube != widget.isYouTube) {
      _youtubeController?.dispose();
      _youtubeController = null;
      _controller?.removeListener(_onControllerChanged);
      _controller = null;
      _error = null;
      _attach();
    }
  }

  Future<void> _attach() async {
    if (_initializing) return;
    _initializing = true;
    if (kDebugMode) debugPrint('[ReelPlayer] attach index=${widget.index} url=${widget.url} youtube=${widget.isYouTube} videoId=$_youtubeId');
    if (widget.isYouTube) {
      final videoId = _youtubeId;
      if (videoId == null || videoId.isEmpty) {
        setState(() => _error = 'Missing YouTube video id');
        _initializing = false;
        return;
      }
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false, loop: true, controlsVisibleAtStart: false),
      )..addListener(_onYoutubeChanged);
      if (mounted) setState(() {});
      _initializing = false;
      return;
    }

    final manager = ref.read(reelsPlaybackManagerProvider);
    try {
      final existing = manager.controllerFor(widget.index);
      if (existing != null) {
        existing.addListener(_onControllerChanged);
        setState(() => _controller = existing);
        _initializing = false;
        return;
      }

      // Only create controller for currently visible index or immediate next
      final current = ref.read(reelsNotifierProvider).currentIndex;
      if (widget.index == current || widget.index == current + 1) {
        final c = await manager.createController(widget.index, widget.url, autoPlay: widget.index == current, looping: true);
        c.addListener(_onControllerChanged);
        if (mounted) setState(() => _controller = c);
      }
      // otherwise do nothing: ReelsNotifier will create when needed
    } catch (e) {
      if (kDebugMode) debugPrint('[ReelPlayer] attach error index=${widget.index} error=$e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _initializing = false;
    }
  }

  void _onControllerChanged() {
    if (!mounted || _controller == null) return;
    final v = _controller!.value;
    if (kDebugMode && v.hasError) {
      debugPrint('[ReelPlayer] controller state index=${widget.index} initialized=${v.isInitialized} playing=${v.isPlaying} error=${v.errorDescription}');
    }
    setState(() {});
  }

  void _onYoutubeChanged() {
    final controller = _youtubeController;
    if (controller == null || !mounted) return;
    final value = controller.value;
    if (kDebugMode) {
      debugPrint('[ReelPlayer] youtube state index=${widget.index} ready=${value.isReady} playing=${value.isPlaying} error=${value.errorCode}');
    }
  }

  @override
  void dispose() {
    // Don't dispose manager-owned controllers here; manager handles pruning.
    _controller?.removeListener(_onControllerChanged);
    _controller = null;
    _youtubeController?.removeListener(_onYoutubeChanged);
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        bottomActions: const [CurrentPosition(), ProgressBar(isExpanded: true), RemainingDuration()],
      );
    }
    if (_error != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _thumbnailOrLoader(),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),
          ),
        ],
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return _thumbnailOrLoader();
    }
    return FittedBox(
      fit: BoxFit.cover,
      alignment: Alignment.center,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _thumbnailOrLoader() {
    return widget.thumbnail != null && widget.thumbnail!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: widget.thumbnail!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 48)),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
