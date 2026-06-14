import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static Future<void> _play(String path) async {
    final player = AudioPlayer();

    await player.setReleaseMode(ReleaseMode.stop);

    try {
      await player.play(AssetSource(path));
    } catch (e) {
      // Debug fallback (silent fail protection)
      print("Audio error: $path -> $e");
    }
  }

  static Future<void> playComplete() => _play('audio/complete_task.mp3');

  static Future<void> playLevelUp() => _play('audio/level_up.mp3');

  static Future<void> playStreak() => _play('audio/streak_update.mp3');

  static Future<void> playClick() => _play('audio/click_soft.mp3');

  static Future<void> playAchievement() =>
      _play('audio/achievement_unlock.mp3');
}
