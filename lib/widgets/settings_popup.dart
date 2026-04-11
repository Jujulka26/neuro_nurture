import 'package:flutter/material.dart';
import '../controllers/music_controller.dart';
import '../controllers/sound_controller.dart';

class SettingsPopup extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onLogout;

  const SettingsPopup({super.key, required this.onClose, required this.onLogout});

  @override
  State<SettingsPopup> createState() => SettingsPopupState();
}

class SettingsPopupState extends State<SettingsPopup> with TickerProviderStateMixin {
  bool isMusicOn = MusicController().isMusicOn;
  bool isSoundOn = SoundController().isSoundOn;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  final SoundController _soundController = SoundController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _toggleMusic() => setState(() {
    isMusicOn = !isMusicOn;
    MusicController().toggleMusic(isMusicOn);
  });

  void _toggleSound() => setState(() {
    isSoundOn = !isSoundOn;
    _soundController.toggleSound(isSoundOn);
  });

  Future<void> closeSettings() async {
    await _slideController.reverse();
    if (mounted) widget.onClose();
  }

  Future<void> _handleLogout() async {
    await _slideController.reverse();
    if (mounted) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 350, minHeight: 180),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color.fromARGB(51, 0, 0, 0), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 5))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Expanded(child: Center(child: Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: closeSettings,
                        color: Colors.black87,
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _toggleMusic,
                    child: Column(
                      children: [
                        isMusicOn
                            ? const Icon(Icons.music_note, color: Colors.blueAccent, size: 40)
                            : const Icon(Icons.music_off, color: Colors.grey, size: 40),
                        const SizedBox(height: 8),
                        Text(isMusicOn ? 'Music ON' : 'Music OFF', style: TextStyle(fontWeight: FontWeight.bold, color: isMusicOn ? Colors.black : Colors.grey)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleSound,
                    child: Column(
                      children: [
                        isSoundOn
                            ? const Icon(Icons.volume_up, color: Colors.blueAccent, size: 40)
                            : const Icon(Icons.volume_off, color: Colors.grey, size: 40),
                        const SizedBox(height: 8),
                        Text(isSoundOn ? 'Sound ON' : 'Sound OFF', style: TextStyle(fontWeight: FontWeight.bold, color: isSoundOn ? Colors.black : Colors.grey)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleLogout,
                    child: const Column(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 40),
                        SizedBox(height: 8),
                        Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}