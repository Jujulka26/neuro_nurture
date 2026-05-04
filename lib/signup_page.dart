import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'start_page.dart';
import 'utils/pin_dialog_utils.dart';
import 'controllers/music_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    MusicController().pauseMusic();
  }

  Future<void> signUp() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      final User? user = userCredential.user;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup failed: User not created.')),
        );
        return;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      final bool hasParentalPin = userDoc.exists && userDoc.data() is Map && (userDoc.data() as Map<String, dynamic>).containsKey('parentalPin');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign Up Successful!')),
      );

      if (!hasParentalPin) {
        if (!mounted) return;
        await showParentalPinSetupDialog(context, user.uid);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StartPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'An unexpected error occurred. Please try again.';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? message;
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 20,
                                child: Image.asset(
                                  'assets/images/ui/logo.png',
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                              Positioned(
                                top: 35,
                                left: 0,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  },
                                  child: Image.asset(
                                    'assets/images/ui/back button.png',
                                    width: 50,
                                    height: 50,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a New Account!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Fredoka One',
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Spacer(),
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF53C2FF),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  shadowColor: Colors.black.withAlpha((255 * 0.25).round()),
                                  elevation: 4,
                                ),
                                onPressed: isLoading ? null : signUp,
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                                    : const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF2F29E0),
                                      decoration: TextDecoration.underline,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 4),
                                          blurRadius: 4,
                                          color: Color(0x40000000),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
