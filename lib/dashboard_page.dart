import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, List<Map<String, dynamic>>> _gameScores = {
    'Group the Shapes': [],
    'Colour Match': [],
    'Sort the Numbers': [],
  };

  final Map<String, String> _skillMapping = {
    'Colour Match': 'Color Recognition, Attention',
    'Group the Shapes': 'Categorization, Visual Processing',
    'Sort the Numbers': 'Sequencing, Working Memory',
  };

  final Map<String, bool> _expanded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllScores();
  }

  Future<void> _fetchAllScores() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      for (String gameName in _gameScores.keys) {
        QuerySnapshot snapshot = await _firestore
            .collection('game_scores')
            .where('userId', isEqualTo: user.uid)
            .where('gameName', isEqualTo: gameName)
            .get();

        List<Map<String, dynamic>> scores = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'score': (data['score'] as num?)?.toInt() ?? 0,
            'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          };
        }).toList();

        scores.removeWhere((s) => s['timestamp'] == null);
        scores.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
        if (scores.length > 10) scores = scores.take(10).toList();

        _gameScores[gameName] = scores;
        _expanded[gameName] = false;
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _calculateStats(String gameName, List<Map<String, dynamic>> scores) {
    if (scores.isEmpty) {
      return {
        'totalGames': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'latestScore': 0.0,
      };
    }
    int totalGames = scores.length;
    List<int> rawScoreValues = scores.map((s) => (s['score'] as int)).toList();
    List<double> displayedScoreValues;

    if (gameName == 'Group the Shapes') {
      const double maxPossibleScoreForShapeGame = 6.0;
      displayedScoreValues = rawScoreValues.map((score) =>
          (score / maxPossibleScoreForShapeGame * 100.0).clamp(0.0, 100.0)).toList();
    } else {
      displayedScoreValues = rawScoreValues.map((score) => score.toDouble()).toList();
    }

    double sumScores = displayedScoreValues.reduce((a, b) => a + b);
    double averageScore = sumScores / totalGames;
    double bestScore = displayedScoreValues.reduce((a, b) => a > b ? a : b);
    double latestScore = displayedScoreValues.first;

    return {
      'totalGames': totalGames,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'latestScore': latestScore,
    };
  }

  Widget _buildWhiteStatText(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildGameCard(String game, List<Map<String, dynamic>> scores) {
    final stats = _calculateStats(game, scores);
    final isExpanded = _expanded[game] ?? false;
    final reversedScores = List<Map<String, dynamic>>.from(scores.reversed);

    List<FlSpot> chartSpots = [];
    if (game == 'Group the Shapes') {
      const double maxPossibleScoreForShapeGame = 6.0;
      for (int i = 0; i < reversedScores.length; i++) {
        double normalizedScore = ((reversedScores[i]['score'] as int) / maxPossibleScoreForShapeGame * 100.0).clamp(0.0, 100.0);
        chartSpots.add(FlSpot(i.toDouble(), normalizedScore));
      }
    } else {
      for (int i = 0; i < reversedScores.length; i++) {
        chartSpots.add(FlSpot(i.toDouble(), (reversedScores[i]['score'] as int).toDouble()));
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withAlpha((255 * 0.5).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded.updateAll((key, value) => false);
            _expanded[game] = !isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$game - ${_skillMapping[game]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.expand_more, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWhiteStatText("Total", stats['totalGames'].toString()),
                _buildWhiteStatText("Avg", "${stats['averageScore'].toStringAsFixed(1)}%"),
                _buildWhiteStatText("Best", "${stats['bestScore'].toStringAsFixed(0)}%"),
                _buildWhiteStatText("Last", "${stats['latestScore'].toStringAsFixed(0)}%"),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            if (index >= 0 && index < reversedScores.length) {
                              return Text(
                                (index + 1).toString(),
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            return Text('${value.toInt()}%',
                                style: const TextStyle(fontSize: 10, color: Colors.white70));
                          },
                          interval: 20,
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Colors.white54),
                        left: BorderSide(color: Colors.white54),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.white12, strokeWidth: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: Colors.white,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(show: true),
                        spots: chartSpots,
                      )
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueAccent,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'Score: ${spot.y.toStringAsFixed(0)}%',
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _showResetParentalPinDialog() async {
    TextEditingController oldPinController = TextEditingController();
    TextEditingController newPinController = TextEditingController();
    TextEditingController confirmNewPinController = TextEditingController();
    String? generalErrorMessage;

    void showSnackbar(String message, {bool isError = false}) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, setState) {
            return AlertDialog(
              title: const Text('Reset Parental PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: oldPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: 'Enter Old PIN',
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: 'Enter New 4-digit PIN',
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmNewPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: 'Confirm New PIN',
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (generalErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          generalErrorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    if (!stfContext.mounted) return;
                    Navigator.of(stfContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      generalErrorMessage = null;
                    });

                    final user = _auth.currentUser;
                    if (user == null) {
                      setState(() {
                        generalErrorMessage = 'User not logged in. Cannot reset PIN.';
                      });
                      return;
                    }

                    try {
                      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
                      final String? storedPIN = (userDoc.data() as Map<String, dynamic>?)?['parentalPin'] as String?;

                      if (storedPIN == null || storedPIN.isEmpty) {
                        setState(() {
                          generalErrorMessage = 'No existing PIN to reset for this user.';
                        });
                        return;
                      }
                      if (oldPinController.text != storedPIN) {
                        setState(() {
                          generalErrorMessage = 'Incorrect Old PIN.';
                        });
                        return;
                      }

                      if (newPinController.text.length != 4 || confirmNewPinController.text.length != 4) {
                        setState(() {
                          generalErrorMessage = 'Both new PIN fields must be 4 digits.';
                        });
                        return;
                      }
                      if (newPinController.text != confirmNewPinController.text) {
                        setState(() {
                          generalErrorMessage = 'New PINs do not match.';
                          newPinController.clear();
                          confirmNewPinController.clear();
                        });
                        return;
                      }

                      await _firestore.collection('users').doc(user.uid).set({
                        'parentalPin': newPinController.text,
                        'pinUpdated': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      showSnackbar('Parental PIN reset successfully!');
                      if (!stfContext.mounted) return;
                      Navigator.of(stfContext).pop();
                    } on FirebaseException catch (e) {
                      setState(() {
                        generalErrorMessage = 'Failed to reset PIN: ${e.message ?? 'Unknown error'}';
                      });
                      showSnackbar(generalErrorMessage!, isError: true);
                    } catch (e) {
                      setState(() {
                        generalErrorMessage = 'An unexpected error occurred: $e';
                      });
                      showSnackbar(generalErrorMessage!, isError: true);
                    }
                  },
                  child: const Text('Reset PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/images/ui/back button.png',
                      height: 50,
                      width: 50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'DASHBOARD',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _iconButton(
                    onPressed: _showResetParentalPinDialog,
                    icon: Icons.lock_reset,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: _fetchAllScores,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _gameScores.keys
                        .map((game) => _buildGameCard(game, _gameScores[game]!))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({required VoidCallback onPressed, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFACCEF7),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Icon(
          icon,
          size: 30,
          color: Colors.black87,
        ),
      ),
    );
  }
}