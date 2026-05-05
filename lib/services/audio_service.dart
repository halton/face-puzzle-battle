/// Audio service for game sounds and background music
/// Uses Flutter's built-in audio capabilities
class AudioService {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _isPlaying = false;

  // Sound effect types
  static const String sfxBlink = 'blink';
  static const String sfxPlace = 'place';
  static const String sfxPerfect = 'perfect';
  static const String sfxGameStart = 'game_start';
  static const String sfxGameEnd = 'game_end';
  static const String sfxCountdown = 'countdown';
  static const String bgmMenu = 'bgm_menu';
  static const String bgmGame = 'bgm_game';
  static const String bgmResult = 'bgm_result';

  // Singleton
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
  }

  /// Play a sound effect
  Future<void> playSfx(String sfxName) async {
    if (!_soundEnabled) return;
    // TODO: Integrate with audioplayers or flame_audio
    // await FlameAudio.play('sfx/$sfxName.mp3');
  }

  /// Play background music
  Future<void> playMusic(String bgmName) async {
    if (!_musicEnabled) return;
    if (_isPlaying) await stopMusic();
    // TODO: Integrate with audioplayers
    // await FlameAudio.bgm.play('music/$bgmName.mp3');
    _isPlaying = true;
  }

  /// Stop background music
  Future<void> stopMusic() async {
    // TODO: FlameAudio.bgm.stop();
    _isPlaying = false;
  }

  /// Pause music
  Future<void> pauseMusic() async {
    // TODO: FlameAudio.bgm.pause();
  }

  /// Resume music
  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;
    // TODO: FlameAudio.bgm.resume();
  }

  void dispose() {
    stopMusic();
  }
}
