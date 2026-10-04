import 'package:audioplayers/audioplayers.dart';

/// Short bundled cues; playback failure never interrupts a quest.
class QuestAudio {
  bool _enabled = false;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) _stop();
  }

  Future<void> _stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  AudioPlayer? _player;
  bool _disposed = false;
  Future<void> play(String cue) async {
    if (!enabled || _disposed) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.play(AssetSource('audio/$cue.wav'), volume: .55);
    } catch (_) {
      // Browsers may block playback before a user gesture.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _player?.dispose();
    } catch (_) {}
  }
}
