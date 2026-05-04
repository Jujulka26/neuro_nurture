import 'package:flutter/material.dart';
import 'dart:async';
import '../controllers/sound_controller.dart';
import '../controllers/music_controller.dart';
import 'main_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleX;
  late Animation<double> _scaleY;

  final SoundController _soundController = SoundController();
  final MusicController _musicController = MusicController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleX = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startAnimationLoop();
    _musicController.init();
  }

  void _startAnimationLoop() async {
    while (mounted) {
      await _controller.forward();
      await _controller.reverse();
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playClickSound() {
    _soundController.playSfx('audio/sfx/click sound.mp3');
  }

  void _navigateToMainPage() {
    _playClickSound();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF3FF),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/ui/logo.png',
                  height: 200,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70.0),
              child: GestureDetector(
                onTap: _navigateToMainPage,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scaleX: _scaleX.value,
                      scaleY: _scaleY.value,
                      child: Image.asset(
                        'assets/images/ui/play button.png',
                        width: 100,
                        height: 100,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
