import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../data/friends_repository.dart';
import 'dart:io' show Platform;

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS 
            ? '509991346553-0ms6f7tiois3vfvcv0beo3ddpcq4l7qs.apps.googleusercontent.com' 
            : null,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user has a username profile setup
        final profile = await FriendsRepository.instance.getMyProfile();
        if (mounted) {
          if (profile == null) {
            context.go('/auth/username');
          } else {
            context.go('/main');
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in with Google')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.authCanvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spacer to push content to the middle
              const Spacer(flex: 2),
              
              // App Icon & Wordmark
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Momento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.5,
                        color: SetlogColors.authInk,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, duration: 800.ms, curve: Curves.easeOutBack),
              
              const Spacer(flex: 3),
              
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: SetlogColors.authTerminalAccent),
                )
              else 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CupertinoButton.filled(
                      onPressed: _isLoading ? null : () => context.go('/auth/email'),
                      borderRadius: BorderRadius.circular(14),
                      child: const Text(
                        'Continue with Email & Password',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      color: SetlogColors.authSurface,
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/google_logo.png', height: 24, width: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: SetlogColors.authInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms, duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
              
              const SizedBox(height: 32),
              
              // Secondary Action (Help Menu)
              Center(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: SetlogColors.authMuted,
                  ),
                  child: const Text(
                    'having trouble logging in?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
