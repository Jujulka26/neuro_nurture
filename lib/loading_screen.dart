import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'controllers/music_controller.dart';

class LoadingScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration loadingDuration;

  const LoadingScreen({
    super.key,
    required this.nextScreen,
    this.loadingDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    MusicController().pauseMusic();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Future.delayed(widget.loadingDuration, () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var scaleTween = Tween<double>(begin: 0.0, end: 1.0);
              var fadeTween = Tween<double>(begin: 0.0, end: 1.0);

              return ScaleTransition(
                scale: scaleTween.animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: FadeTransition(
                  opacity: fadeTween.animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/loading.json',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Text(
              'Getting ready to play!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[700],
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading game...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}