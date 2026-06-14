class AudioService {
  static bool _enabled = false;

  static Future<void> init() async {}

  static bool get isEnabled => _enabled;

  static void setEnabled(bool value) {
    _enabled = value;
  }

  static Future<void> playClick() async {}

  static Future<void> playOpen() async {}

  static Future<void> playAddTask() async {}

  static Future<void> playComplete() async {}

  static Future<void> playDelete() async {}

  static Future<void> playLevelUp() async {}

  static Future<void> playAchievement() async {}

  static Future<void> playError() async {}

  static Future<void> dispose() async {}
}
