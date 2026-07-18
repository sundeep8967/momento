import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/auth/auth_landing_screen.dart';
import '../presentation/auth/permissions_screen.dart';
import '../presentation/auth/auth_email_screen.dart';
import '../presentation/auth/username_setup_screen.dart';
import '../presentation/auth/onboarding_screen.dart';
import '../presentation/main/collections_home_screen.dart';
import '../presentation/main/camera_capture_screen.dart';
import '../presentation/main/friend_log_viewer_screen.dart';
import '../presentation/main/own_log_viewer_screen.dart';
import '../presentation/main/friends_screen.dart';
import '../presentation/main/profile_screen.dart';
import '../presentation/splash/animated_splash_screen.dart';
import '../theme/colors.dart';

CustomTransitionPage<void> _fadeRoute(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadeRoute(state, const AnimatedSplashScreen()),
    ),
    // ── Auth Flow ──
    ShellRoute(
      builder: (context, state, child) => Scaffold(
        backgroundColor: SetlogColors.authCanvas,
        body: child,
      ),
      routes: [
        GoRoute(
          path: '/auth/landing',
          pageBuilder: (context, state) => _fadeRoute(state, const AuthLandingScreen()),
        ),
        GoRoute(
          path: '/auth/email',
          pageBuilder: (context, state) => _fadeRoute(state, const AuthEmailScreen()),
        ),
        GoRoute(
          path: '/auth/username',
          pageBuilder: (context, state) => _fadeRoute(state, const UsernameSetupScreen()),
        ),
        GoRoute(
          path: '/auth/permissions',
          pageBuilder: (context, state) => _fadeRoute(state, const PermissionsScreen()),
        ),
        GoRoute(
          path: '/auth/onboarding',
          pageBuilder: (context, state) => _fadeRoute(state, const OnboardingScreen()),
        ),
      ],
    ),

    // ── Main App ──
    GoRoute(
      path: '/main',
      pageBuilder: (context, state) => _fadeRoute(state, const CollectionsHomeScreen()),
      routes: [
        GoRoute(
          path: 'camera',
          pageBuilder: (context, state) => _fadeRoute(state, const CameraCaptureScreen()),
        ),
        GoRoute(
          path: 'daylog/:logId',
          pageBuilder: (context, state) {
            final logId = state.pathParameters['logId']!;
            return _fadeRoute(state, OwnLogViewerScreen(logId: logId));
          },
        ),
        GoRoute(
          path: 'profile',
          pageBuilder: (context, state) => _fadeRoute(state, const ProfileScreen()),
        ),
      ],
    ),

    // ── Friends & Social ──
    GoRoute(
      path: '/friends',
      pageBuilder: (context, state) => _fadeRoute(state, const FriendsScreen()),
      routes: [
        GoRoute(
          path: 'log/:shareId',
          pageBuilder: (context, state) {
            final shareId = state.pathParameters['shareId']!;
            return _fadeRoute(state, FriendLogViewerScreen(shareId: shareId));
          },
        ),
        GoRoute(
          path: 'add/:username',
          pageBuilder: (context, state) {
            final username = state.pathParameters['username']!;
            return _fadeRoute(state, FriendsScreen(initialSearch: username));
          },
        ),
      ],
    ),
  ],
);
