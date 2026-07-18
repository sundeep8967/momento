import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/friends_repository.dart';
import '../../theme/colors.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  final String _targetText = 'Momento';
  String _currentText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    // Wait a bit before starting the animation so it feels seamless with native splash
    Future.delayed(const Duration(milliseconds: 300), () {
      _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        if (_currentIndex < _targetText.length) {
          setState(() {
            _currentText += _targetText[_currentIndex];
            _currentIndex++;
          });
        } else {
          _timer?.cancel();
          // Wait a second after finishing typing, then check auth and redirect
          Future.delayed(const Duration(milliseconds: 800), () {
            _checkAuthAndRedirect();
          });
        }
      });
    });
  }

  Future<void> _checkAuthAndRedirect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/auth/landing');
      return;
    }

    try {
      final profile = await FriendsRepository.instance.getMyProfile();
      if (mounted) {
        if (profile == null) {
          context.go('/auth/username');
        } else {
          context.go('/main');
        }
      }
    } catch (_) {
      if (mounted) context.go('/auth/landing');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.authCanvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Removed splash image as per request
            const SizedBox(height: 24),
            Text(
              _currentText,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.5,
                color: SetlogColors.authInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
