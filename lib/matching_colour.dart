import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:math';
import 'package:neuro_nurture/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controllers/music_controller.dart';
import 'controllers/sound_controller.dart';

const Duration _revealItemDelay = Duration(milliseconds: 600);
const Duration _postRevealAudioDelay = Duration(milliseconds: 300);
const Duration _animationDuration = Duration(milliseconds: 1000);
const Duration _initialRevealDelay = Duration(milliseconds: 800);

class Item {
  final String name, color, image;
  Item({required this.name, required this.color, required this.image});

  @override
  bool operator ==(Object other) => identical(this, other) || other is Item && runtimeType == other.runtimeType && name == other.name && color == other.color && image == other.image;

  @override
  int get hashCode => name.hashCode ^ color.hashCode ^ image.hashCode;
}

class QuestionData {
  final List<String> targetColors;
  final int numOptions, numCorrectAnswers;
  final List<Item> options;
  final List<int> correctOptionIndices;
  final Map<String, int> targetColorCounts;

  QuestionData({required this.targetColors, required this.numOptions, required this.numCorrectAnswers, required this.options, required this.correctOptionIndices, required this.targetColorCounts});

  int get numWrongOptions => numOptions - numCorrectAnswers;
  double get pointsPerCorrectTap => numCorrectAnswers == 0 ? 0.0 : 1.0 / numCorrectAnswers;
  double get penaltyPerWrongTap => numWrongOptions == 0 ? 0.0 : 1.0;
}

class MatchingColourScreen extends StatefulWidget {
  const MatchingColourScreen({super.key});
  @override
  State<MatchingColourScreen> createState() => _MatchingColourScreenState();
}

class _MatchingColourScreenState extends State<MatchingColourScreen> with TickerProviderStateMixin {
  final SoundController _soundController = SoundController();
  final Random _random = Random();

  final List<Item> allItems = [
    Item(name: 'Apple', color: 'red', image: 'assets/apple.png'),
    Item(name: 'Durian', color: 'green', image: 'assets/durian.png'),
    Item(name: 'Blueberry', color: 'blue', image: 'assets/blueberry.png'),
    Item(name: 'Orange', color: 'orange', image: 'assets/orange.png'),
    Item(name: 'Elephant', color: 'blue', image: 'assets/elephant.png'),
    Item(name: 'Tiger', color: 'orange', image: 'assets/tiger.png'),
    Item(name: 'Lemon', color: 'yellow', image: 'assets/lemon.png'),
    Item(name: 'Dragon Fruit', color: 'pink', image: 'assets/dragon fruit.png'),
    Item(name: 'Grape', color: 'purple', image: 'assets/grape.png'),
    Item(name: 'Dragon', color: 'red', image: 'assets/dragon.png'),
    Item(name: 'Duck', color: 'yellow', image: 'assets/duck.png'),
    Item(name: 'Turtle', color: 'green', image: 'assets/turtle.png'),
    Item(name: 'Axolotl', color: 'pink', image: 'assets/axolotl.png'),
    Item(name: 'Jellyfish', color: 'purple', image: 'assets/jellyfish.png'),
  ];

  late List<String> availableColors;
  List<QuestionData> questions = [];
  int currentIndex = 0;
  bool showOptions = true;
  List<bool> showEachItem = [], itemEnabled = [];
  late AnimationController _wrongAnswerController, _correctAnswerController;
  bool _showWrongAnswerAnimation = false, _showCorrectAnswerAnimation = false;
  int _voiceToggle = 0;
  bool isProcessing = false, _canInteract = false;
  double _rawScore = 0.0;
  final double _maxPossibleRawScore = 7.0;
  final Set<int> _tappedCorrectIndices = {};
  bool _isInstructionVoicePlaying = false;

  @override
  void initState() {
    super.initState();
    MusicController().changeBackgroundMusic('Piki - Healing Spell (freetouse.com).mp3', fadeIn: true);
    availableColors = allItems.map((e) => e.color).toSet().toList();
    _generateQuestions();
    _revealItems();
    _wrongAnswerController = AnimationController(vsync: this, duration: _animationDuration);
    _correctAnswerController = AnimationController(vsync: this, duration: _animationDuration);
  }

  List<Item> _getNUniqueItemsOfColor(String color, int count) {
    List<Item> availableForColor = allItems.where((item) => item.color == color).toList();
    availableForColor.shuffle(_random);
    return availableForColor.take(count).toList();
  }

  List<String> _getRandomColors(int count) {
    List<String> colorsToPickFrom = List.from(availableColors);
    colorsToPickFrom.shuffle(_random);
    return colorsToPickFrom.take(count).toList();
  }

  void _addQuestionSafely(List<String> targetColors, int numOptions, List<Item> initialCorrectItems, Map<String, int> targetColorCounts) {
    List<Item> options = [...initialCorrectItems];
    int wrongItemsNeeded = numOptions - options.length;

    if (wrongItemsNeeded > 0) {
      List<Item> wrongItemsCandidates = allItems.where((item) => !targetColors.contains(item.color) && !options.contains(item)).toList()..shuffle(_random);
      options.addAll(wrongItemsCandidates.take(wrongItemsNeeded));
    }

    while (options.length < numOptions) {
      List<Item> fillerItems = allItems.where((item) => !options.contains(item)).toList()..shuffle(_random);
      if (fillerItems.isNotEmpty) {
        options.add(fillerItems.first);
      } else {
        break;
      }
    }

    if (options.length == numOptions) {
      options.shuffle(_random);
      List<int> correctOptionIndices = [];
      for (int i = 0; i < options.length; i++) {
        if (initialCorrectItems.contains(options[i])) correctOptionIndices.add(i);
      }
      if (correctOptionIndices.length == initialCorrectItems.length) {
        questions.add(QuestionData(targetColors: targetColors, numOptions: numOptions, numCorrectAnswers: initialCorrectItems.length, options: options, correctOptionIndices: correctOptionIndices, targetColorCounts: targetColorCounts));
      }
    }
  }

  void _generateQuestions() {
    questions.clear();
    availableColors = allItems.map((e) => e.color).toSet().toList();

    void createQuestionSafely({required int correctAnswersCount, required int numOptions, int targetColorCount = 1, required Function(List<String>) itemSelectionLogic}) {
      List<String> selectedColors = [];
      List<Item> correctItems = [];
      Map<String, int> actualTargetColorCounts = {};
      bool generationSuccess = false;

      for (int i = 0; i < 100; i++) {
        selectedColors = _getRandomColors(targetColorCount);
        if (selectedColors.length < targetColorCount) {
          continue;
        }
        correctItems.clear();
        actualTargetColorCounts.clear();
        try {
          List<Item> generatedItems = itemSelectionLogic(selectedColors);
          if (generatedItems.length == correctAnswersCount) {
            correctItems.addAll(generatedItems);
            for (var item in generatedItems) {
              actualTargetColorCounts.update(item.color, (value) => value + 1, ifAbsent: () => 1);
            }
            generationSuccess = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (generationSuccess) {
        _addQuestionSafely(selectedColors, numOptions, correctItems, actualTargetColorCounts);
      } else {
        List<String> fallbackColors = [_getRandomColors(1).first];
        List<Item> fallbackItems = _getNUniqueItemsOfColor(fallbackColors[0], 1);
        Map<String, int> fallbackCounts = {fallbackColors[0]: 1};
        if (fallbackItems.isNotEmpty) {
          _addQuestionSafely(fallbackColors, 2, fallbackItems, fallbackCounts);
        }
      }
    }

    List<Item> getSingleColorItems(List<String> colors, int count) {
      if (colors.isEmpty) {
        return [];
      }
      List<Item> itemsOfColor = allItems.where((item) => item.color == colors[0]).toList();
      if (itemsOfColor.length < count) {
        throw Exception("Not enough items of color ${colors[0]} for count $count.");
      }
      itemsOfColor.shuffle(_random);
      return itemsOfColor.take(count).toList();
    }

    List<Item> getTwoColorItems(List<String> colors, int count1, int count2) {
      if (colors.length < 2) {
        throw Exception("Not enough colors for two-color question.");
      }
      List<Item> items = [];
      List<Item> itemsColor1 = allItems.where((item) => item.color == colors[0]).toList();
      if (itemsColor1.length < count1) {
        throw Exception("Not enough items of color ${colors[0]} for count $count1.");
      }
      itemsColor1.shuffle(_random);
      items.addAll(itemsColor1.take(count1));
      List<Item> itemsColor2 = allItems.where((item) => item.color == colors[1] && !items.contains(item)).toList();
      if (itemsColor2.length < count2) {
        throw Exception("Not enough items of color ${colors[1]} for count $count2.");
      }
      itemsColor2.shuffle(_random);
      items.addAll(itemsColor2.take(count2));
      return items;
    }

    createQuestionSafely(correctAnswersCount: 1, numOptions: 2, targetColorCount: 1, itemSelectionLogic: (colors) => getSingleColorItems(colors, 1));
    createQuestionSafely(correctAnswersCount: 1, numOptions: 3, targetColorCount: 1, itemSelectionLogic: (colors) => getSingleColorItems(colors, 1));
    createQuestionSafely(correctAnswersCount: 2, numOptions: 3, targetColorCount: 1, itemSelectionLogic: (colors) => getSingleColorItems(colors, 2));
    createQuestionSafely(correctAnswersCount: 2, numOptions: 4, targetColorCount: 2, itemSelectionLogic: (colors) => getTwoColorItems(colors, 1, 1));
    createQuestionSafely(correctAnswersCount: 3, numOptions: 4, targetColorCount: 2, itemSelectionLogic: (colors) {
      try {
        return getTwoColorItems(colors, 2, 1);
      } catch (e) {
        return getTwoColorItems([colors[1], colors[0]], 2, 1);
      }
    });
    createQuestionSafely(correctAnswersCount: 3, numOptions: 5, targetColorCount: 2, itemSelectionLogic: (colors) {
      try {
        return getTwoColorItems(colors, 2, 1);
      } catch (e) {
        return getTwoColorItems([colors[1], colors[0]], 2, 1);
      }
    });
    createQuestionSafely(correctAnswersCount: 4, numOptions: 5, targetColorCount: 2, itemSelectionLogic: (colors) => getTwoColorItems(colors, 2, 2));

    while (questions.length < 7) {
      List<String> fallbackColors = [_getRandomColors(1).first];
      List<Item> fallbackItems = _getNUniqueItemsOfColor(fallbackColors[0], 1);
      Map<String, int> fallbackCounts = {fallbackColors[0]: 1};
      if (fallbackItems.isNotEmpty) {
        _addQuestionSafely(fallbackColors, 2, fallbackItems, fallbackCounts);
      }
    }
    if (questions.length > 7) {
      questions = questions.sublist(0, 7);
    }
  }

  void _revealItems() async {
    if (!mounted || questions.isEmpty || currentIndex >= questions.length) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    QuestionData currentQuestion = questions[currentIndex];
    setState(() {
      showEachItem = List<bool>.filled(currentQuestion.numOptions, false);
      itemEnabled = List<bool>.filled(currentQuestion.numOptions, true);
      showOptions = false;
      _tappedCorrectIndices.clear();
      _showWrongAnswerAnimation = false;
      _showCorrectAnswerAnimation = false;
      isProcessing = false;
      _canInteract = false;
      _isInstructionVoicePlaying = false;
    });

    Future.delayed(_initialRevealDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        showOptions = true;
      });

      for (int i = 0; i < currentQuestion.numOptions; i++) {
        Future.delayed(_revealItemDelay * (i + 1), () {
          if (!mounted || i >= showEachItem.length) {
            return;
          }
          setState(() {
            showEachItem[i] = true;
          });
          if (i == currentQuestion.numOptions - 1) {
            Future.delayed(_postRevealAudioDelay, () async {
              if (!mounted) {
                return;
              }
              setState(() {
                _canInteract = true;
              });
              await _playInstructionVoiceOver(currentQuestion);
            });
          }
        });
      }
    });
  }

  Future<void> _playInstructionVoiceOver(QuestionData question) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isInstructionVoicePlaying = true;
    });

    try {
      await _soundController.playSfx('choose voice over.mp3');
      if (!mounted || !_isInstructionVoicePlaying) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted || !_isInstructionVoicePlaying) {
        return;
      }

      int colorCountIndex = 0;
      for (String color in question.targetColorCounts.keys) {
        if (!mounted || !_isInstructionVoicePlaying) {
          return;
        }

        int count = question.targetColorCounts[color]!;
        if (colorCountIndex > 0) {
          await _soundController.playSfx('and voice over.mp3');
          if (!mounted || !_isInstructionVoicePlaying) {
            return;
          }
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted || !_isInstructionVoicePlaying) {
            return;
          }
        }

        String countFile = count == 1 ? 'one voice over.mp3' : count == 2 ? 'two voice over.mp3' : '';
        if (countFile.isNotEmpty) {
          await _soundController.playSfx(countFile);
          if (!mounted || !_isInstructionVoicePlaying) {
            return;
          }
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted || !_isInstructionVoicePlaying) {
            return;
          }
        }

        await _soundController.playSfx('$color voice over.mp3');
        if (!mounted || !_isInstructionVoicePlaying) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted || !_isInstructionVoicePlaying) {
          return;
        }

        colorCountIndex++;
      }

      if (!mounted || !_isInstructionVoicePlaying) {
        return;
      }
      String finalFile = question.numCorrectAnswers > 1 ? 'colours voice over.mp3' : 'colour voice over.mp3';
      await _soundController.playSfx(finalFile);

    } catch (e) {
      // Handle any errors silently
    } finally {
      if (mounted) {
        setState(() {
          _isInstructionVoicePlaying = false;
        });
      }
    }
  }

  void _stopInstructionVoice() {
    if (_isInstructionVoicePlaying) {
      setState(() {
        _isInstructionVoicePlaying = false;
      });
    }
  }

  void onItemTap(Item item, int index) async {
    if (!mounted || isProcessing || !_canInteract || index < 0 || index >= itemEnabled.length || !itemEnabled[index]) {
      return;
    }

    _stopInstructionVoice();

    QuestionData currentQuestionData = questions[currentIndex];

    if (currentQuestionData.correctOptionIndices.contains(index)) {
      if (!_tappedCorrectIndices.contains(index)) {
        _tappedCorrectIndices.add(index);
        setState(() {
          _rawScore += currentQuestionData.pointsPerCorrectTap;
          itemEnabled[index] = false;
          _showCorrectAnswerAnimation = true;
          isProcessing = true;
          _canInteract = false;
        });

        _correctAnswerController.reset();
        await _correctAnswerController.forward();

        if (!mounted) {
          return;
        }

        await _soundController.playSfx('${item.color} voice over.mp3');

        if (!mounted) {
          return;
        }

        setState(() {
          _showCorrectAnswerAnimation = false;
        });

        if (_tappedCorrectIndices.length == currentQuestionData.numCorrectAnswers) {
          if (!mounted) {
            return;
          }
          if (currentIndex + 1 < questions.length) {
            _showLevelCompletionDialog();
          } else {
            _nextQuestion();
          }
        } else {
          if (mounted) {
            setState(() {
              isProcessing = false;
              _canInteract = true;
            });
          }
        }
      }
    } else {
      setState(() {
        isProcessing = true;
        _canInteract = false;
        itemEnabled[index] = false;
        _rawScore -= currentQuestionData.penaltyPerWrongTap;
        _showWrongAnswerAnimation = true;
      });

      _wrongAnswerController.reset();
      await _wrongAnswerController.forward();

      String voiceFile = _voiceToggle == 0 ? 'good try voice over.mp3' : 'try again voice over.mp3';
      _voiceToggle = 1 - _voiceToggle;
      await _soundController.playSfx(voiceFile);
      if (!mounted) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        return;
      }

      setState(() {
        _showWrongAnswerAnimation = false;
        isProcessing = false;
        for (int i = 0; i < itemEnabled.length; i++) {
          if (!currentQuestionData.correctOptionIndices.contains(i) && !itemEnabled[i]) {
            itemEnabled[i] = true;
          }
        }
        _canInteract = true;
      });
    }
  }


  void _showLevelCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.lightBlue.shade300.withAlpha((0.9 * 255).round()),
          title: const Text('Level Complete!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: const Text('Great job! You matched the colors correctly.', style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                await _soundController.playSfx('click sound.mp3');
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                _nextQuestion();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen.shade300, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), elevation: 5),
              child: const Text('Next Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _nextQuestion() async {
    if (!mounted) {
      return;
    }
    setState(() {
      isProcessing = false;
      showOptions = false;
      _tappedCorrectIndices.clear();
      _showWrongAnswerAnimation = false;
      _showCorrectAnswerAnimation = false;
      _canInteract = false;
      _isInstructionVoicePlaying = false;
    });

    if (currentIndex + 1 < questions.length) {
      currentIndex++;
      _revealItems();
    } else {
      double normalizedScore = (_rawScore / _maxPossibleRawScore) * 100;
      int finalScore100 = normalizedScore.round().clamp(0, 100);

      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        FirestoreService().saveGameScore(userId: userId, gameName: 'Colour Match', score: finalScore100);
      }

      await _soundController.playSfx('awesome voice over.mp3');
      if (!mounted) {
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.2 * 255).round()), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Game Finished!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('Your total score: $finalScore100 / 100', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  _buildScoreStars(isInDialog: true, score100: finalScore100),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        await _soundController.playSfx('click sound.mp3');
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('OK', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildScoreStars({bool isInDialog = false, int? score100}) {
    int filledStars = 0;
    double scorePercentage = (score100 != null) ? (score100 / 100.0) : (_rawScore / _maxPossibleRawScore);
    if (scorePercentage >= 0.7) {
      filledStars = 3;
    } else if (scorePercentage >= 0.5) {
      filledStars = 2;
    } else if (scorePercentage >= 0.3) {
      filledStars = 1;
    } else {
      filledStars = 0;
    }
    double starSize = isInDialog ? 30 : 24;
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (index) => Icon(index < filledStars ? Icons.star : Icons.star_border, color: Colors.yellow[700], size: starSize)));
  }

  Color _getColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow[700]!;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  @override
  void dispose() {
    _stopInstructionVoice();
    _wrongAnswerController.dispose();
    _correctAnswerController.dispose();
    MusicController().changeBackgroundMusic('background music.mp3', fadeIn: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/matching colour background image.png', fit: BoxFit.cover),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    QuestionData currentQuestionData = questions[currentIndex];
    final Map<int, List<int>> layoutIndices = {2: [1, 3], 3: [0, 2, 4], 4: [0, 1, 3, 4], 5: [0, 1, 2, 3, 4]};
    final List<int> currentLayout = layoutIndices[currentQuestionData.numOptions] ?? layoutIndices[5]!;

    final List<Widget> gridChildren = List.generate(5, (gridIndex) {
      if (currentLayout.contains(gridIndex)) {
        int itemIndex = currentLayout.indexOf(gridIndex);
        if (itemIndex < currentQuestionData.options.length) {
          final item = currentQuestionData.options[itemIndex];
          final bool show = showEachItem[itemIndex];
          final bool enabled = itemEnabled[itemIndex];
          final double offsetY = (gridIndex == 0 || gridIndex == 2 || gridIndex == 4) ? -30.0 : 0.0;

          return AnimatedOpacity(
            duration: _revealItemDelay,
            opacity: show ? (enabled ? 1.0 : 0.3) : 0.0,
            child: Transform.translate(
              offset: Offset(0.0, offsetY),
              child: Center(
                child: GestureDetector(
                  onTap: _canInteract && enabled ? () => onItemTap(item, itemIndex) : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: enabled ? null : Border.all(color: Colors.grey.shade400, width: 2)),
                        child: Padding(padding: const EdgeInsets.all(20.0), child: SizedBox(width: 120, height: 120, child: Image.asset(item.image, fit: BoxFit.contain))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
      return const SizedBox.shrink();
    });

    List<InlineSpan> instructionSpans = [const TextSpan(text: 'Choose ', style: TextStyle(fontSize: 24, color: Colors.black))];
    int colorIndex = 0;
    for (String color in currentQuestionData.targetColorCounts.keys) {
      int count = currentQuestionData.targetColorCounts[color]!;
      if (colorIndex > 0) {
        instructionSpans.add(const TextSpan(text: ' and ', style: TextStyle(color: Colors.black, fontSize: 24)));
      }
      instructionSpans.add(TextSpan(text: '$count ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getColor(color))));
      instructionSpans.add(TextSpan(text: color.toUpperCase(), style: TextStyle(color: _getColor(color), fontWeight: FontWeight.bold, fontSize: 24)));
      colorIndex++;
    }
    instructionSpans.add(TextSpan(text: ' colour${currentQuestionData.numCorrectAnswers > 1 ? 's' : ''}.', style: const TextStyle(fontSize: 24, color: Colors.black)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/matching colour background image.png', fit: BoxFit.cover),
          Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    GestureDetector(onTap: () {
                      _soundController.playSfx('click sound.mp3');
                      Navigator.pop(context);
                    }, child: Image.asset('assets/back button.png', width: 50, height: 50)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withAlpha((0.4 * 255).round()), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${currentIndex + 1}/${questions.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(offset: Offset(1, 1), blurRadius: 2.0, color: Colors.black54)])),
                          const SizedBox(width: 10),
                          _buildScoreStars(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text.rich(TextSpan(children: instructionSpans), textAlign: TextAlign.center))),
              const SizedBox(height: 80),
              Expanded(child: showOptions ? GridView.count(padding: const EdgeInsets.all(12), crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.0, children: gridChildren) : const SizedBox()),
              const SizedBox(height: 20),
            ],
          ),
          if (_showWrongAnswerAnimation)
            Center(
              child: Lottie.asset(
                'assets/wrong.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                repeat: false,
                controller: _wrongAnswerController,
              ),
            ),
          if (_showCorrectAnswerAnimation)
            Center(
              child: Lottie.asset(
                'assets/correct.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                repeat: false,
                controller: _correctAnswerController,
              ),
            ),
        ],
      ),
    );
  }
}