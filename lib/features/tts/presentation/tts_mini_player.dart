import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_player_manager.dart';
import '../tts_providers.dart';

class TtsMiniPlayer extends ConsumerStatefulWidget {
  const TtsMiniPlayer({super.key});

  @override
  ConsumerState<TtsMiniPlayer> createState() => _TtsMiniPlayerState();
}

class _TtsMiniPlayerState extends ConsumerState<TtsMiniPlayer> {
  final _mgr = AudioPlayerManager();

  @override
  void dispose() {
    // do not dispose singleton here; app lifecycle owns it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tts = ref.watch(ttsNotifierProvider);
    if (tts.audioUrl == null && !tts.loading) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          IconButton(
              onPressed: () async {
                if (tts.playing) {
                  await _mgr.pause();
                  ref.read(ttsNotifierProvider.notifier).setPlaying(false);
                } else {
                  if (tts.audioUrl != null) {
                    await _mgr.setUrl(tts.audioUrl!);
                    await _mgr.play();
                    ref.read(ttsNotifierProvider.notifier).setPlaying(true);
                  }
                }
              },
              icon: Icon(tts.playing ? Icons.pause : Icons.play_arrow)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tts.error != null ? 'TTS Error' : (tts.loading ? 'Preparing audio...' : 'Playing article audio'), style: Theme.of(context).textTheme.bodyMedium),
            if (tts.audioUrl != null) Text(tts.audioUrl!, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ])),
          IconButton(onPressed: () async { await _mgr.stop(); await ref.read(ttsNotifierProvider.notifier).stopPlayback(); }, icon: const Icon(Icons.close))
        ]),
      ),
    );
  }
}
