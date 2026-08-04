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
          if (profile == null || profile.username.isEmpty || profile.username == '@') {
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

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFDF4F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFB8CF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A0A10),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Icon(CupertinoIcons.xmark_circle_fill,
                          color: Color(0xFFEFB8CF), size: 28),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFEFB8CF), height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: const [
                    _TermsSection(
                      title: '1. Acceptance of Terms',
                      body:
                          'By downloading, installing, or using Momento ("the App"), you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the App.',
                    ),
                    _TermsSection(
                      title: '2. Privacy & Data',
                      body:
                          'We collect only the data necessary to provide the service, including your Google account email and profile photo. All media you share is end-to-end encrypted. We do not sell your personal data to third parties.',
                    ),
                    _TermsSection(
                      title: '3. Ephemeral Content',
                      body:
                          'Moments (photos and videos) shared through the App are ephemeral and will be deleted after being viewed. You must not capture, screenshot, or record another user\'s Moments without their consent.',
                    ),
                    _TermsSection(
                      title: '4. User Conduct',
                      body:
                          'You agree not to use the App to share illegal, harmful, abusive, defamatory, or sexually explicit content. Violation of this policy may result in immediate account termination.',
                    ),
                    _TermsSection(
                      title: '5. Intellectual Property',
                      body:
                          'All content you upload remains your property. By sharing it through Momento, you grant us a limited license to store and deliver it solely for the purpose of operating the service.',
                    ),
                    _TermsSection(
                      title: '6. Limitation of Liability',
                      body:
                          'Momento is provided "as is" without warranties of any kind. We are not liable for any indirect or consequential damages arising from your use of the App.',
                    ),
                    _TermsSection(
                      title: '7. Changes to Terms',
                      body:
                          'We may update these Terms from time to time. Continued use of the App after changes are posted constitutes your acceptance of the revised Terms.',
                    ),
                    _TermsSection(
                      title: '8. Contact',
                      body:
                          'For questions about these Terms, please contact us at support@momento.app.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    const SizedBox(height: 12),
                    // Inline T&C consent — App Store compliant
                    GestureDetector(
                      onTap: () => _showTermsModal(context),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9A6070),
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: 'By continuing, you agree to our '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                                color: SetlogColors.momentoPink,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                                color: SetlogColors.momentoPink,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
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

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE8729A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF4A2030),
            ),
          ),
        ],
      ),
    );
  }
}
