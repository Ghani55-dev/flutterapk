import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reels/models.dart';
import '../../../providers/reels_providers.dart';
import 'widgets/reel_player.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/auth_controller.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reelsNotifierProvider);
    final notifier = ref.read(reelsNotifierProvider.notifier);
    final items = state.items;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            onPageChanged: (i) {
              notifier.onPageChanged(i);
            },
            itemBuilder: (_, i) {
              final v = items[i] as VideoItem;
              return Stack(
                fit: StackFit.expand,
                children: [
                  ReelPlayer(index: i, url: v.url, thumbnail: v.thumbnail, isYouTube: v.isYouTube, youtubeVideoId: v.youtubeVideoId),
                  Positioned(
                    left: 16,
                    bottom: 24,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (v.sourceName != null) Text(v.sourceName!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 48,
                    child: Column(
                      children: [
                        IconButton(icon: const Icon(Icons.thumb_up, color: Colors.white), onPressed: () {}),
                        const SizedBox(height: 12),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border, color: Colors.white),
                          onPressed: () async {
                            final auth = ref.read(authNotifierProvider);
                            if (auth.status != AuthStatus.authenticated) {
                              if (!mounted) return;
                              await showAuthGate(context);
                              return;
                            }
                            // TODO: implement bookmark action for reels
                          },
                        ),
                        const SizedBox(height: 12),
                        IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
          if (items.isEmpty) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
