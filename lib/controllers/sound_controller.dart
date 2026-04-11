import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundController {
  static final SoundController _instance = SoundController._internal();
  factory SoundController() => _instance;
  SoundController._internal();

  bool _isSoundOn = true;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _voiceOverPlayer = AudioPlayer();

  bool get isSoundOn => _isSoundOn;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundOn = prefs.getBool('isSoundOn') ?? true;
    await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> toggleSound(bool isOn) async {
    _isSoundOn = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundOn', isOn);
    if (!isOn) {
      await _sfxPlayer.stop();
      await _voiceOverPlayer.stop();
    }
  }

  Future<void> playSfx(String audioPath) async {
    if (_isSoundOn) {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(audioPath));
    }
  }

  Future<void> playVoiceOver(String audioPath) async {
    if (_isSoundOn) {
      await _voiceOverPlayer.stop();
      await _voiceOverPlayer.play(AssetSource(audioPath));
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _voiceOverPlayer.dispose();
  }
}