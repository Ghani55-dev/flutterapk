import 'dart:async';
import 'package:state_notifier/state_notifier.dart';
import 'data/tts_repository.dart';

class TtsState {
  final bool loading;
  final String? taskId;
  final String? audioUrl;
  final String? error;
  final bool playing;
  TtsState({this.loading = false, this.taskId, this.audioUrl, this.error, this.playing = false});
  TtsState copyWith({bool? loading, String? taskId, String? audioUrl, String? error, bool? playing}) =>
      TtsState(loading: loading ?? this.loading, taskId: taskId ?? this.taskId, audioUrl: audioUrl ?? this.audioUrl, error: error ?? this.error, playing: playing ?? this.playing);
}

class TtsNotifier extends StateNotifier<TtsState> {
  final TtsRepository repository;
  Timer? _pollTimer;
  TtsNotifier({required this.repository}) : super(TtsState());

  Future<void> requestTts({required String content, String language = 'en', required String objectType, required String objectId}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await repository.requestTts(content: content, language: language, objectType: objectType, objectId: objectId);
      // server may return file_url (ready) or task_id (queued)
      if (resp.containsKey('file_url')) {
        state = state.copyWith(loading: false, audioUrl: resp['file_url'], taskId: null);
      } else if (resp.containsKey('task_id')) {
        final tid = resp['task_id'].toString();
        state = state.copyWith(loading: false, taskId: tid, audioUrl: null);
        _startPolling(tid);
      } else {
        state = state.copyWith(loading: false, error: 'Unexpected server response');
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void _startPolling(String taskId) {
    _pollTimer?.cancel();
    var attempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      attempts++;
      if (attempts > 30) {
        t.cancel();
        state = state.copyWith(error: 'TTS generation timeout');
        return;
      }
      try {
        final s = await repository.getStatus(taskId);
        final status = (s['status'] ?? s['state'] ?? '').toString().toUpperCase();
        if (status == 'SUCCESS' && s.containsKey('file_url')) {
          _pollTimer?.cancel();
          state = state.copyWith(audioUrl: s['file_url'], taskId: null);
          return;
        } else if (status == 'FAILURE') {
          _pollTimer?.cancel();
          state = state.copyWith(error: s['error']?.toString() ?? 'Generation failed', taskId: null);
          return;
        }
        // otherwise still pending
      } catch (e) {
        // continue; don't spam
      }
    });
  }

  void cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Mark playback state
  void setPlaying(bool playing) {
    state = state.copyWith(playing: playing);
  }

  /// Force set audio url (useful when external player handles playback)
  void setAudioUrl(String url) {
    state = state.copyWith(audioUrl: url);
  }

  Future<void> stopPlayback() async {
    setPlaying(false);
  }

  @override
  void dispose() {
    cancelPolling();
    super.dispose();
  }
}
