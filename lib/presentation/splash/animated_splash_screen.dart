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
  @override
  void initState() {
    super.initState();
    // Start auth check after a brief delay for the logo animation
    Future.delayed(const Duration(milliseconds: 1500), _checkAuthAndRedirect);
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
    } catch (e) {
      if (mounted) context.go('/auth/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Apple style pure black splash
      body: Center(
        child: Image.asset(
          'assets/app_icon.png',
          width: 120,
          height: 120,
        )
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}
