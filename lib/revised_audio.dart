import 'package:audioplayers/audioplayers.dart';

/// A quiet, locally bundled instrumental bed for the revised Explore scenes.
/// Narration continues to use the app's existing offline text-to-speech voice.
class LessonMusic {
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  Future<void> play(double volume) async {
    try {
      await _player.setVolume(volume * .08);
      if (!_ready) {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('revised/audio/explore_ambient.wav'));
        _ready = true;
      } else {
        await _player.resume();
      }
    } catch (_) {
      // An unavailable platform audio backend must not block lesson progress.
    }
  }
  Future<void> setVolume(double volume) async {
    try {await _player.setVolume(volume * .08);} catch (_) {}
  }
  Future<void> pause() async {try {await _player.pause();} catch (_) {}}
  Future<void> stop() async {try {await _player.stop(); _ready = false;} catch (_) {}}
  Future<void> dispose() async {try {await _player.dispose();} catch (_) {}}
}
