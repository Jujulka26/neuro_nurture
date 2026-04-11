import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuro_nurture/services/firestore_service.dart';
import 'package:neuro_nurture/controllers/music_controller.dart';
import 'package:neuro_nurture/controllers/sound_controller.dart';

class NumberSortingGame extends StatefulWidget {
  const NumberSortingGame({super.key});

  @override
  State<NumberSortingGame> createState() => _NumberSortingGameState();
}

class _NumberSortingGameState extends State<NumberSortingGame> with SingleTickerProviderStateMixin {
  List<int> _numbersToDrag = [];
  List<int?> _sortedSlots = [];
  List<int> _correctOrder = [];
  int _currentQuestion = 1;
  final int _totalQuestions = 8;
  bool _isAscending = true;
  String _backgroundImagePath = 'assets/asc background image.png';
  final Random _random = Random();
  int _score = 0;
  int _incorrectDrops = 0;
  final double _maxPossibleRawScore = 32.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final MusicController _musicController = MusicController();
  final SoundController _soundController = SoundController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnimation = Tween<double>(begin: 1.1, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _soundController.init();
    _musicController.changeBackgroundMusic('Piki - Happy Walking (freetouse.com).mp3', fadeIn: true);
    _generateQuestion(_currentQuestion);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _musicController.changeBackgroundMusic('background music.mp3', fadeIn: false);
    super.dispose();
  }

  void _playSound(String assetPath) => _soundController.playSfx(assetPath);
  void _playVoiceOver(String assetPath) => _soundController.playVoiceOver(assetPath);

  void _generateQuestion(int questionNumber) {
    int numberOfElements;
    int maxNumber;
    bool wasAscending = _isAscending;

    _isAscending = questionNumber <= 6;
    _backgroundImagePath = _isAscending ? 'assets/asc background image.png' : 'assets/desc background image.png';
    _playVoiceOver(_isAscending ? 'small to large voice over.mp3' : 'large to small voice over.mp3');

    if (_isAscending) {
      if (questionNumber <= 2) {
        numberOfElements = 3; maxNumber = 5;
      } else if (questionNumber <= 4) {
        numberOfElements = 4; maxNumber = 10;
      } else {
        numberOfElements = 5; maxNumber = 15;
      }
    } else {
      numberOfElements = 5; maxNumber = 15;
    }

    if (wasAscending != _isAscending) {
      _animationController.reset();
      _animationController.forward();
    }

    Set<int> uniqueNumbers = {};
    while (uniqueNumbers.length < numberOfElements) {
      uniqueNumbers.add(_random.nextInt(maxNumber) + 1);
    }

    _correctOrder = uniqueNumbers.toList();
    if (_isAscending) {
      _correctOrder.sort();
    } else {
      _correctOrder.sort((a, b) => b.compareTo(a));
    }

    _numbersToDrag = uniqueNumbers.toList()..shuffle(_random);
    _sortedSlots = List<int?>.filled(numberOfElements, null);
    setState(() {});
  }

  void _onNumberDropped(int draggedNumber, int targetIndex) {
    if (_sortedSlots[targetIndex] == null && draggedNumber == _correctOrder[targetIndex]) {
      setState(() {
        _numbersToDrag.remove(draggedNumber);
        _sortedSlots[targetIndex] = draggedNumber;
        _score++;
        _playSound('put sound.mp3');

        if (_numbersToDrag.isEmpty && _sortedSlots.every((e) => e != null)) {
          if (_currentQuestion == 6) {
            _showTransitionDialog();
          } else if (_currentQuestion < _totalQuestions) {
            _showCompletionDialog(isGameComplete: false);
          } else {
            _showCompletionDialog(isGameComplete: true);
          }
        }
      });
    } else {
      setState(() {
        _incorrectDrops++;
        _playSound('wrong sound.mp3');
      });
    }
  }

  void _showTransitionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.orange.shade300.withAlpha((0.9 * 255).round()),
        title: const Text('New Challenge!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text('Get ready! Now sort numbers from LARGE to SMALL!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              _playSound('click sound.mp3');
              Navigator.of(dialogContext).pop();
              _currentQuestion++;
              _generateQuestion(_currentQuestion);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), elevation: 5),
            child: const Text('Start Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog({required bool isGameComplete}) {
    double rawCalculatedScore = _score - (_incorrectDrops * 0.5);
    double normalizedScore = (rawCalculatedScore / _maxPossibleRawScore) * 100;
    int finalScore100 = normalizedScore.round().clamp(0, 100);

    if (isGameComplete) _playVoiceOver('awesome voice over.mp3');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.lightBlue.shade300.withAlpha((0.9 * 255).round()),
        title: Text(isGameComplete ? 'Game Over!' : 'Level Complete!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isGameComplete ? 'Congratulations! You\'ve completed all $_totalQuestions questions!' : 'Great job! You sorted the numbers correctly.', style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
            if (isGameComplete) ...[
              const SizedBox(height: 10),
              Text('Your total score: $finalScore100 / 100', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildScoreIcons(isInDialog: true, score100: finalScore100),
            ]
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          ElevatedButton(
            onPressed: () async {
              _playSound('click sound.mp3');
              Navigator.of(dialogContext).pop();
              if (isGameComplete) {
                final String? userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  await FirestoreService().saveGameScore(userId: userId, gameName: 'Sort the Numbers', score: finalScore100);
                }
                if (mounted) Navigator.of(context).pop();
              } else {
                _currentQuestion++;
                _generateQuestion(_currentQuestion);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen.shade300, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), elevation: 5),
            child: Text(isGameComplete ? 'Done' : 'Next Question', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIcons({bool isInDialog = false, int? score100}) {
    double scorePercentage = isInDialog ? score100! / 100.0 : max(0.0, (_score - (_incorrectDrops * 0.5))) / _maxPossibleRawScore;
    int filledTrophies = scorePercentage >= 0.7 ? 3 : (scorePercentage >= 0.5 ? 2 : (scorePercentage >= 0.3 ? 1 : 0));
    double iconSize = isInDialog ? 30 : 24;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) => Icon(index < filledTrophies ? Icons.diamond : Icons.diamond_outlined, color: Colors.cyanAccent, size: iconSize)),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextSpan instructionTextSpan = TextSpan(
      children: [
        TextSpan(text: 'Level $_currentQuestion: Sort numbers from ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        TextSpan(text: _isAscending ? 'SMALL' : 'LARGE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isAscending ? Colors.blue.shade700 : Colors.red.shade700)),
        const TextSpan(text: ' to ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        TextSpan(text: _isAscending ? 'LARGE' : 'SMALL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isAscending ? Colors.red.shade700 : Colors.blue.shade700)),
        const TextSpan(text: '.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );

    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue.shade200, primary: Colors.lightBlue.shade300, onPrimary: Colors.white, secondary: Colors.lightGreen.shade300, onSecondary: Colors.white, surface: Colors.grey.shade100, onSurface: Colors.black87),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(decoration: BoxDecoration(image: DecorationImage(image: AssetImage(_backgroundImagePath), fit: BoxFit.cover))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () { _playSound('click sound.mp3'); Navigator.pop(context); },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/back button.png', width: 50, height: 50),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withAlpha((0.4 * 255).round()), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$_currentQuestion/$_totalQuestions', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(offset: Offset(1, 1), blurRadius: 2.0, color: Colors.black54)])),
                            const SizedBox(width: 10),
                            _buildScoreIcons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text.rich(instructionTextSpan, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: 15.0,
                        runSpacing: 15.0,
                        alignment: WrapAlignment.center,
                        children: _numbersToDrag.map((number) => Draggable<int>(
                          data: number,
                          feedback: Material(color: Colors.transparent, child: NumberCard(number: number, isFeedback: true)),
                          childWhenDragging: Container(
                            width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade400, width: 2)),
                            child: Center(child: Text(number.toString(), style: TextStyle(fontSize: 30, color: Colors.grey.shade500))),
                          ),
                          child: NumberCard(number: number),
                        )).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    decoration: BoxDecoration(color: Colors.white.withAlpha((0.7 * 255).round()), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.1 * 255).round()), blurRadius: 10, offset: const Offset(0, 5))]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_correctOrder.length, (index) => DragTarget<int>(
                        onWillAcceptWithDetails: (details) => _sortedSlots[index] == null,
                        onAcceptWithDetails: (details) => _onNumberDropped(details.data, index),
                        builder: (context, candidateData, rejectedData) => Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: _sortedSlots[index] != null ? Colors.lightGreen.shade300.withAlpha((0.8 * 255).round()) : (candidateData.isNotEmpty ? Colors.lightGreen.shade300.withAlpha((0.3 * 255).round()) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _sortedSlots[index] != null ? Colors.lightGreen.shade300 : (candidateData.isNotEmpty ? Colors.lightGreen.shade300 : Colors.grey.shade400), width: 2),
                          ),
                          child: Center(
                            child: _sortedSlots[index] != null ? Text(_sortedSlots[index].toString(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)) : Icon(Icons.drag_handle, size: 40, color: Colors.grey.shade500),
                          ),
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberCard extends StatelessWidget {
  final int number;
  final bool isFeedback;

  const NumberCard({super.key, required this.number, this.isFeedback = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isFeedback ? 10 : 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isFeedback ? Colors.lightBlue.shade300.withAlpha((0.8 * 255).round()) : Colors.lightBlue.shade300,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(number.toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.none)),
      ),
    );
  }
}