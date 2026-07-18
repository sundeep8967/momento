import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      HapticFeedback.heavyImpact();
      context.go('/main');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.authCanvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  HapticFeedback.selectionClick();
                },
                children: [
                  _buildPage(
                    icon: Icons.videocam_rounded,
                    title: 'Record Your Day',
                    subtitle: 'Capture moments up to 5 seconds. Add a quick caption and save it to your daily log.',
                    delay: 0,
                  ),
                  _buildPage(
                    icon: Icons.lock_clock_rounded,
                    title: 'Auto-Shares at Midnight',
                    subtitle: 'Your daily log stays private all day. At midnight, it compiles and shares with your squad.',
                    delay: 100,
                  ),
                  _buildPage(
                    icon: Icons.auto_delete_rounded,
                    title: 'Disappears in 24 Hours',
                    subtitle: 'No permanent feeds. Shared logs disappear forever after 24 hours. Keep it real, keep it raw.',
                    delay: 200,
                  ),
                ],
              ),
            ),
            
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDot(index)),
            ),
            const SizedBox(height: 32),
            
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: SetlogColors.authInk,
                  foregroundColor: SetlogColors.authCanvas,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _currentIndex == 2 ? "Let's Go!" : "Continue",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ).animate(target: _currentIndex == 2 ? 1 : 0).shimmer(duration: 1000.ms, color: Colors.white24),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required IconData icon, required String title, required String subtitle, required int delay}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: SetlogColors.authTerminalAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: SetlogColors.authTerminalAccent)
                .animate(key: ValueKey(_currentIndex))
                .scale(duration: 500.ms, curve: Curves.easeOutBack, delay: delay.ms),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: SetlogColors.authInk,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ).animate(key: ValueKey(_currentIndex)).fadeIn(duration: 400.ms, delay: (delay + 100).ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: SetlogColors.authMuted,
              height: 1.4,
            ),
          ).animate(key: ValueKey(_currentIndex)).fadeIn(duration: 400.ms, delay: (delay + 200).ms),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentIndex == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentIndex == index ? SetlogColors.authTerminalAccent : SetlogColors.authStrokeSoft,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
