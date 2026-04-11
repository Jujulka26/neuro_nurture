import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/sound_controller.dart';
import '../controllers/music_controller.dart';

class ShapeGame extends StatefulWidget {
  const ShapeGame({super.key});

  @override
  ShapeGameState createState() => ShapeGameState();
}

class ShapeGameState extends State<ShapeGame> with TickerProviderStateMixin {
  List<ShapeData> imageRandom = [];
  List<ShapeData> dragImage = [];
  int level = 1;
  List<bool> matched = List.generate(3, (index) => false);
  int score = 0;
  int life = 5;

  final SoundController _soundController = SoundController();
  final MusicController _musicController = MusicController();

  late List<AnimationController> animationControllers;
  late List<Animation<Offset>> animations;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<ShapeData> baseShapes = const [
    ShapeData(id: 'square', imagePath: 'assets/square3.png'),
    ShapeData(id: 'triangle', imagePath: 'assets/triangle4.png'),
    ShapeData(id: 'circle', imagePath: 'assets/circle1.png'),
  ];

  final List<ShapeData> baseCuteShapes = const [
    ShapeData(id: 'square', imagePath: 'assets/squareCute1.png'),
    ShapeData(id: 'triangle', imagePath: 'assets/triangleCute1.png'),
    ShapeData(id: 'circle', imagePath: 'assets/circleCute1.png'),
  ];

  @override
  void initState() {
    super.initState();
    _soundController.init();
    _musicController.changeBackgroundMusic('Piki - Kitty (freetouse.com).mp3', fadeIn: true);
    _initializeGame();
    _initializeAnimations();
  }

  @override
  void dispose() {
    for (var controller in animationControllers) {
      controller.dispose();
    }
    _musicController.changeBackgroundMusic('background music.mp3', fadeIn: false);
    super.dispose();
  }

  void _initializeAnimations() {
    animationControllers = List.generate(3, (index) =>
        AnimationController(duration: const Duration(milliseconds: 300), vsync: this));
    animations = animationControllers.map((controller) =>
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(controller)).toList();
  }

  void _initializeGame() {
    setState(() {
      imageRandom = _getRandomImages();
      dragImage = _getDragImages();
      matched = List.generate(3, (index) => false);
    });
  }

  List<ShapeData> _getRandomImages() {
    List<ShapeData> selectedShapes = [];
    List<ShapeData> shuffledBaseShapes = List.from(baseShapes)..shuffle();
    for (int i = 0; i < 3; i++) {
      selectedShapes.add(shuffledBaseShapes[i % shuffledBaseShapes.length]);
    }
    selectedShapes.shuffle();
    return selectedShapes;
  }

  List<ShapeData> _getDragImages() {
    List<ShapeData> selectedShapes = [];
    List<ShapeData> shuffledBaseCuteShapes = List.from(baseCuteShapes)..shuffle();
    for (int i = 0; i < 3; i++) {
      selectedShapes.add(shuffledBaseCuteShapes[i % shuffledBaseCuteShapes.length]);
    }
    selectedShapes.shuffle();
    return selectedShapes;
  }

  void _playGameSound(String soundType) {
    String soundPath;
    switch (soundType) {
      case 'click':
        soundPath = 'click sound.mp3';
        break;
      case 'correct':
        soundPath = 'correct sound.mp3';
        break;
      case 'wrong':
        soundPath = 'wrong sound.mp3';
        break;
      case 'gameOver':
        soundPath = 'gameover sound.mp3';
        break;
      default:
        return;
    }
    _soundController.playSfx(soundPath);
  }

  void _checkMatch(int dragIndex, int dropIndex) {
    final draggedShape = dragImage[dragIndex];
    final targetShape = imageRandom[dropIndex];

    if (draggedShape.id == targetShape.id) {
      _playGameSound('correct');
      setState(() {
        matched[dropIndex] = true;
      });

      if (matched.every((element) => element)) {
        if (level == 6) {
          _nextLevel();
        } else {
          _showDialog(
            title: 'Correct!',
            content: 'All shapes matched!',
            buttonText: 'Next Level',
            onPressed: _nextLevel,
          );
        }
      }
    } else {
      _playGameSound('wrong');
      setState(() {
        life -= 1;
        if (life <= 0) {
          _gameOver();
        }
      });
    }
    _resetAllDragPositions();
  }

  void _nextLevel() {
    if (level == 6) {
      _saveData(score + 1);
      _showDialog(
        title: 'Game Completed!',
        content: 'You completed all 6 levels! Your final score is: $score',
        buttonText: 'Back to Game Page',
        onPressed: _handleBackPage,
      );
    } else {
      setState(() {
        score += 1;
        level += 1;
        imageRandom = _getRandomImages();
        dragImage = _getDragImages();
        matched = List.generate(3, (index) => false);
      });
      _resetAllDragPositions();
    }
  }

  void _gameOver() {
    _saveData(score);
    _playGameSound('gameOver');

    _showDialog(
      title: 'Game Over!',
      content: 'Your Score is: $score',
      buttonText: 'Back to Game Page',
      onPressed: _handleBackPage,
    );
  }

  void _resetAllDragPositions() {
    for (var controller in animationControllers) {
      controller.reset();
    }
  }

  void _showDialog({
    required String title,
    required String content,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _soundController.playSfx('click sound.mp3');
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      onPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      elevation: 5,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveData(int finalScoreToSave) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('game_scores').add({
        'userId': user.uid,
        'gameName': 'Group the Shapes',
        'score': finalScoreToSave,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // You might want to show a SnackBar or other UI feedback in a real app
      // For now, we'll just acknowledge the error.
    }
  }

  void _handleBackPage() {
    _playGameSound('click');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildGameBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _handleBackPage,
            child: Image.asset(
              'assets/back button.png',
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBody() {
    return Column(
      children: [
        const Text(
          'Match the SHAPE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0000AA),
          ),
        ),
        const SizedBox(height: 5),
        _buildGameInfo(),
        const SizedBox(height: 10),
        Expanded(child: _buildGameArea()),
      ],
    );
  }

  Widget _buildGameInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Score: $score',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Level: $level/6',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Life: ${'❤️' * life}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: imageRandom.asMap().entries.map((entry) {
              int dropIndex = entry.key;
              ShapeData targetShape = entry.value;

              return DragTarget<int>(
                onWillAcceptWithDetails: (details) => !matched[dropIndex],
                onAcceptWithDetails: (details) => _checkMatch(details.data, dropIndex),
                builder: (context, candidateData, rejectedData) {
                  Color boxColor = Colors.white;
                  if (matched[dropIndex]) {
                    boxColor = Colors.green.withAlpha((0.3 * 255).round());
                  } else if (candidateData.isNotEmpty) {
                    boxColor = Colors.blue.withAlpha((0.3 * 255).round());
                  }

                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.3 * 255).round()),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        targetShape.imagePath,
                        fit: BoxFit.contain,
                        color: matched[dropIndex] ? Colors.white.withAlpha((0.5 * 255).round()) : null,
                        colorBlendMode: matched[dropIndex] ? BlendMode.modulate : null,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: dragImage.asMap().entries.map((entry) {
              int dragIndex = entry.key;
              ShapeData shape = entry.value;

              bool isAlreadyMatched = imageRandom.asMap().entries.any((e) => e.value.id == shape.id && matched[e.key]);

              if (isAlreadyMatched) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }

              return Draggable<int>(
                data: dragIndex,
                feedback: Material(
                  color: Colors.transparent,
                  child: _buildShapeContainer(shape, isFeedback: true),
                ),
                childWhenDragging: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _buildShapeContainer(shape),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeContainer(ShapeData shape, {bool isFeedback = false}) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isFeedback ? Colors.white.withAlpha((0.8 * 255).round()) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.3 * 255).round()),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          shape.imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class ShapeData {
  final String id;
  final String imagePath;

  const ShapeData({required this.id, required this.imagePath});
}