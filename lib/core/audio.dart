import 'package:audioplayers/audioplayers.dart';

import 'data.dart';

/// Sound effects + background music (all assets synthesized by tool/gen_audio.py).
class Sfx {
  static final _music = AudioPlayer();
  static final _pour = AudioPlayer();
  static final List<AudioPlayer> _pool = List.generate(6, (_) => AudioPlayer());
  static int _next = 0;
  static bool _musicOn = false;

  static Future<void> init() async {
    await _music.setReleaseMode(ReleaseMode.loop);
    await _pour.setReleaseMode(ReleaseMode.loop);
    for (final p in _pool) {
      await p.setPlayerMode(PlayerMode.lowLatency);
    }
    syncMusic();
  }

  static void play(String name, {double volume = 1}) {
    if (!GameData.I.sfx) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    p.stop().then((_) => p.play(AssetSource('audio/$name.wav'), volume: volume)).catchError((_) {});
  }

  static void click() => play('click', volume: .7);

  static void pour(bool on) {
    if (on && GameData.I.sfx) {
      _pour.play(AssetSource('audio/pour.wav'), volume: .55).catchError((_) {});
    } else {
      _pour.stop().catchError((_) {});
    }
  }

  static void syncMusic() {
    final want = GameData.I.music;
    if (want && !_musicOn) {
      _musicOn = true;
      _music.play(AssetSource('audio/music.wav'), volume: .35).catchError((_) {});
    } else if (!want && _musicOn) {
      _musicOn = false;
      _music.stop().catchError((_) {});
    }
  }

  static void pauseAll() {
    _music.pause().catchError((_) {});
    _pour.stop().catchError((_) {});
  }

  static void resume() {
    if (_musicOn) _music.resume().catchError((_) {});
  }
}
