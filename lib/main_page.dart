import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_page.dart';
import 'dashboard_page.dart';
import 'widgets/settings_popup.dart';
import 'controllers/sound_controller.dart';
import 'login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _showSettingsPanel = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final SoundController _soundController = SoundController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _playClickSound() {
    _soundController.playSfx('click sound.mp3');
  }

  void _openSettings() {
    _playClickSound();
    setState(() {
      _showSettingsPanel = true;
    });
  }

  void _closeSettingsPanel() {
    setState(() {
      _showSettingsPanel = false;
    });
  }

  void _onLogoutRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    await _auth.signOut();

    _closeSettingsPanel();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  void _navigateToGamePage() {
    _playClickSound();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamePage()),
    );
  }

  void _navigateToDashboardPage() {
    _playClickSound();
    _showPINPrompt();
  }

  void _showPINPrompt() {
    TextEditingController pinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Parental Access Required'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter 4-digit PIN',
                      errorText: errorMessage,
                    ),
                    onChanged: (value) {
                      setState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    _soundController.playSfx('click sound.mp3');
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      errorMessage = null;
                    });

                    final user = _auth.currentUser;
                    if (user == null) {
                      setState(() {
                        errorMessage = 'User not logged in. Please re-login.';
                      });
                      _soundController.playSfx('click sound.mp3');
                      return;
                    }

                    try {
                      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
                      final String? storedPIN = (userDoc.data() as Map<String, dynamic>?)?['parentalPin'] as String?;

                      if (storedPIN == null || storedPIN.isEmpty) {
                        setState(() {
                          errorMessage = 'No PIN set for this user. Please set it via login/signup.';
                        });
                        _soundController.playSfx('click sound.mp3');
                        return;
                      }

                      if (pinController.text == storedPIN) {
                        _soundController.playSfx('click sound.mp3');
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardPage()),
                        );
                      } else {
                        setState(() {
                          errorMessage = 'Incorrect PIN!';
                        });
                        pinController.clear();
                        _soundController.playSfx('click sound.mp3');
                      }
                    } catch (e) {
                      setState(() {
                        errorMessage = 'Error verifying PIN: $e';
                      });
                      _soundController.playSfx('click sound.mp3');
                    }
                  },
                  child: const Text('Submit'),
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 42),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 280,
                    height: 95,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: _menuButton(
                      imageAsset: 'assets/game icon.png',
                      text: 'GAME',
                      onPressed: _navigateToGamePage,
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: _menuButton(
                      imageAsset: 'assets/dashboard icon.png',
                      text: 'DASHBOARD',
                      onPressed: _navigateToDashboardPage,
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: _menuButton(
                      icon: Icons.lock,
                      text: 'LOCKED FEATURE',
                      onPressed: () {
                        _playClickSound();
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        _playClickSound();
                        Navigator.pop(context);
                      },
                      child: Image.asset(
                        'assets/back button.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    _iconButton(onPressed: _openSettings),
                  ],
                ),
              ),
            ),
            if (_showSettingsPanel)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSettingsPanel,
                  child: Container(
                    color: Colors.black.withAlpha((255 * 0.5).round()),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80.0),
                        child: SettingsPopup(
                          onClose: _closeSettingsPanel,
                          onLogout: _onLogoutRequested,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({required VoidCallback onPressed}) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFACCEF7),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: ClipOval(
          child: Image.asset(
            'assets/setting icon.png',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _menuButton({
    IconData? icon,
    String? imageAsset,
    required String text,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF0F0F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.2).round()),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageAsset != null)
                Image.asset(
                  imageAsset,
                  width: 24,
                  height: 24,
                )
              else if (icon != null)
                Icon(icon, size: 24, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
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