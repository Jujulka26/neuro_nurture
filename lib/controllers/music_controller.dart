import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicController with WidgetsBindingObserver {
  static final MusicController _instance = MusicController._internal();
  factory MusicController() => _instance;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isMusicOn = true;
  bool _isInitialized = false;
  double _currentVolume = 0.2;

  MusicController._internal() {
    WidgetsBinding.instance.addObserver(this);
    _loadMusicPreference();
  }

  Future<void> _loadMusicPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicOn = prefs.getBool('isMusicOn') ?? true;
  }

  Future<void> _saveMusicPreference(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicOn', isOn);
  }

  Future<void> init({bool fadeIn = false}) async {
    if (_isInitialized) return;

    await _loadMusicPreference();

    await _bgmPlayer.setSource(AssetSource('audio/music/background music.mp3'));
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _isInitialized = true;

    if (_isMusicOn) {
      _currentVolume = fadeIn ? 0.01 : 0.2;
      await _bgmPlayer.setVolume(_currentVolume);
      await _bgmPlayer.resume();
      if (fadeIn) {
        await fadeInMusic(targetVolume: 0.2, duration: const Duration(seconds: 1));
      }
    }
  }

  Future<void> playMusic() async {
    if (!_isInitialized) {
      await init();
    }
    if (_isMusicOn && _bgmPlayer.state != PlayerState.playing) {
      await _bgmPlayer.resume();
    }
  }

  void pauseMusic() {
    if (_bgmPlayer.state == PlayerState.playing) {
      _bgmPlayer.pause();
    }
  }

  Future<void> toggleMusic(bool isOn) async {
    _isMusicOn = isOn;
    await _saveMusicPreference(isOn);

    if (isOn) {
      await playMusic();
    } else {
      pauseMusic();
    }
  }

  bool get isMusicOn => _isMusicOn;

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _bgmPlayer.dispose();
  }

  Future<void> fadeInMusic({double targetVolume = 1.0, Duration duration = const Duration(seconds: 1)}) async {
    const int steps = 30;
    double volumeDifference = targetVolume - _currentVolume;
    double stepVolume = volumeDifference / steps;

    for (int i = 0; i <= steps; i++) {
      double newVolume = _currentVolume + (i * stepVolume);
      newVolume = newVolume.clamp(0.0, 1.0);
      await _bgmPlayer.setVolume(newVolume);
      _currentVolume = newVolume;
      await Future.delayed(duration ~/ steps);
    }
  }

  double _getVolumeForAsset(String musicAsset) {
    if (musicAsset == 'audio/music/background music.mp3') {
      return 0.2;
    } else if (musicAsset == 'audio/music/Piki - Healing Spell (freetouse.com).mp3') {
      return 0.03;
    } else {
      return 0.04;
    }
  }

  Future<void> changeBackgroundMusic(String newMusicAsset, {bool fadeIn = false, double? targetVolume}) async {
    final newSource = AssetSource(newMusicAsset);

    if (!_isInitialized) {
      await init();
    }

    double volumeToUse;
    if (targetVolume != null) {
      volumeToUse = targetVolume;
    } else {
      volumeToUse = _getVolumeForAsset(newMusicAsset);
    }

    bool needsSourceChange = true;
    try {
      if (_bgmPlayer.source != null && _bgmPlayer.source.toString() == newSource.toString()) {
        needsSourceChange = false;
      }
    } catch (e) {
      needsSourceChange = true;
    }

    if (needsSourceChange) {
      await _bgmPlayer.stop();
      await _bgmPlayer.setSource(newSource);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    }

    if (_isMusicOn) {
      if (fadeIn) {
        await _bgmPlayer.setVolume(0.01);
        _currentVolume = 0.01;

        if (_bgmPlayer.state != PlayerState.playing) {
          await _bgmPlayer.resume();
        }

        await fadeInMusic(targetVolume: volumeToUse, duration: const Duration(seconds: 1));
      } else {
        _currentVolume = volumeToUse;
        await _bgmPlayer.setVolume(_currentVolume);

        if (_bgmPlayer.state != PlayerState.playing) {
          await _bgmPlayer.resume();
        }
      }
    } else {
      _currentVolume = volumeToUse;
      await _bgmPlayer.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _bgmPlayer.pause();
        break;
      case AppLifecycleState.resumed:
        if (_isMusicOn) {
          _bgmPlayer.resume();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
