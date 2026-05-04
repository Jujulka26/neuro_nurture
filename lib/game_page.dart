import 'package:flutter/material.dart';
import 'matching_colour.dart';
import 'sorting_number.dart';
import 'matching_shape.dart';
import 'controllers/sound_controller.dart';
import 'loading_screen.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final SoundController _soundController = SoundController();

  void _playClickSound() {
    _soundController.playSfx('audio/sfx/click sound.mp3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 5,
                      child: InkWell(
                        onTap: () {
                          _playClickSound();
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          'assets/images/ui/back button.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        "LET'S PLAY",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGameCard(
                      context,
                      "Group the Shapes",
                      'assets/images/ui/group the shape.png',
                          () {
                        _playClickSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoadingScreen(
                              nextScreen: const ShapeGame(),
                              loadingDuration: const Duration(milliseconds: 1500),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 64),
                    _buildGameCard(
                      context,
                      "Colour Match",
                      'assets/images/ui/matching colour.png',
                          () {
                        _playClickSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoadingScreen(
                              nextScreen: const MatchingColourScreen(),
                              loadingDuration: const Duration(milliseconds: 1500),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 64),
                    _buildGameCard(
                      context,
                      "Sort the Numbers",
                      'assets/images/ui/sort number.png',
                          () {
                        _playClickSound();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoadingScreen(
                              nextScreen: const NumberSortingGame(),
                              loadingDuration: const Duration(milliseconds: 1500),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context,
      String title,
      String imagePath,
      VoidCallback onTap,
      ) {
    return SizedBox(
      width: 160,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.1).round()),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(2, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
