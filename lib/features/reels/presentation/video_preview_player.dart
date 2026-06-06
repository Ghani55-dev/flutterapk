import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final String url;
  final bool isYouTube;
  final String? youtubeVideoId;

  const VideoPreviewPlayer({super.key, required this.url, this.isYouTube = false, this.youtubeVideoId});

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _ytController;
  bool _initializing = false;
  String? _error;

  String? get _youtubeId => widget.youtubeVideoId ?? YoutubePlayer.convertUrlToId(widget.url);

  @override
  void initState() {
    super.initState();
    _log('[VIDEO PREVIEW CLICK]');
    _log('[VIDEO URL] ${widget.url}');
    _attachPlayer();
  }

  Future<void> _attachPlayer() async {
    if (_initializing) return;
    _initializing = true;
    try {
      if (widget.isYouTube || (widget.url.contains('youtube.com') || widget.url.contains('youtu.be'))) {
        _log('[VIDEO TYPE] YoutubePlayer');
        final id = _youtubeId;
        if (id == null || id.isEmpty) throw StateError('Missing Youtube id for url ${widget.url}');
        _ytController = YoutubePlayerController(
          initialVideoId: id,
          flags: const YoutubePlayerFlags(autoPlay: true, mute: false, loop: false),
        )..addListener(_onYoutubeChanged);
        if (kDebugMode) _log('[VIDEO INIT] Youtube controller created id=$id');
        if (kDebugMode) _log('[VIDEO PLAY STARTED] url=${widget.url} type=YoutubePlayer id=$id');
        setState(() {});
        return;
      }

      // treat as network media (mp4/m3u8/other)
      _log('[VIDEO TYPE] VideoPlayer');
      final uri = Uri.parse(widget.url);
      _videoController = VideoPlayerController.networkUrl(uri)
        ..addListener(_onVideoChanged);

      // initialize with timeout to avoid infinite loader
      try {
        await _videoController!.initialize().timeout(const Duration(seconds: 8));
      } catch (t) {
        throw StateError('Initialization timeout or failure for url ${widget.url}: $t');
      }

      // attempt play with timeout
      try {
        await _videoController!.play().timeout(const Duration(seconds: 5));
      } catch (t) {
        // Playing might fail silently on some streams; treat as non-fatal but log
        _log('[VIDEO PLAY FAILED] play failed for url=${widget.url} error=$t');
      }

      if (kDebugMode) _log('[VIDEO INIT] VideoPlayer initialized duration=${_videoController!.value.duration}');
      if (kDebugMode) _log('[VIDEO PLAY STARTED] url=${widget.url} type=VideoPlayer duration=${_videoController!.value.duration}');
      setState(() {});
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) {
        _log('[INITIALIZE FAIL] $e');
        _log('[LIVE PLAY FAILED] url=${widget.url} error=$e');
        debugPrint(st.toString());
      }
      // show snackbar once UI mounts
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback failed: ${e.toString()}')));
          } catch (_) {}
        });
      }
      setState(() {});
    } finally {
      _initializing = false;
    }
  }

  void _onVideoChanged() {
    final c = _videoController;
    if (c == null) return;
    if (kDebugMode && c.value.hasError) {
      _log('[VIDEO ERROR] ${c.value.errorDescription}');
      if (kDebugMode) _log('[LIVE PLAY FAILED] url=${widget.url} error=${c.value.errorDescription}');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: ${c.value.errorDescription}')));
          } catch (_) {}
        });
      }
    }
    setState(() {});
  }

  void _onYoutubeChanged() {
    final c = _ytController;
    if (c == null) return;
    final v = c.value;
    if (kDebugMode) _log('[YOUTUBE STATE] ready=${v.isReady} playing=${v.isPlaying} error=${v.errorCode}');
    if (kDebugMode && v.isReady && v.isPlaying) {
      _log('[LIVE PLAY STARTED] url=${widget.url} type=YoutubePlayer id=${_youtubeId ?? ''}');
    }
    setState(() {});
  }

  void _log(String s) {
    if (kDebugMode) debugPrint(s);
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    _ytController?.pause();
    _ytController?.removeListener(_onYoutubeChanged);
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Playback error: $_error', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _log('[VIDEO RETRY] url=${widget.url}');
                        setState(() {
                          _error = null;
                        });
                        _attachPlayer();
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _ytController != null
                ? YoutubePlayer(controller: _ytController!, showVideoProgressIndicator: true)
                : (_videoController == null || !_videoController!.value.isInitialized)
                    ? const CircularProgressIndicator()
                    : AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_ytController != null) {
      final playing = _ytController!.value.isPlaying;
      return FloatingActionButton(
        onPressed: () {
          if (playing) {
            _ytController!.pause();
            _log('[ACTION] youtube pause');
          } else {
            _ytController!.play();
            _log('[ACTION] youtube play');
          }
          setState(() {});
        },
        child: Icon(playing ? Icons.pause : Icons.play_arrow),
      );
    }
    if (_videoController != null && _videoController!.value.isInitialized) {
      final playing = _videoController!.value.isPlaying;
      return FloatingActionButton(
        onPressed: () {
          if (playing) {
            _videoController!.pause();
            _log('[ACTION] video pause');
          } else {
            _videoController!.play();
            _log('[ACTION] video play');
          }
          setState(() {});
        },
        child: Icon(playing ? Icons.pause : Icons.play_arrow),
      );
    }
    return null;
  }
}
