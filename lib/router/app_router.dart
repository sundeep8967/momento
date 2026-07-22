import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/auth/auth_landing_screen.dart';
import '../presentation/auth/permissions_screen.dart';
import '../presentation/auth/auth_email_screen.dart';
import '../presentation/auth/username_setup_screen.dart';
import '../presentation/auth/onboarding_screen.dart';
import '../presentation/main/collections_home_screen.dart';
import '../presentation/main/camera_capture_screen.dart';
import '../presentation/main/send_to_screen.dart';
import '../presentation/main/friend_log_viewer_screen.dart';
import '../presentation/main/own_log_viewer_screen.dart';
import '../presentation/main/friends_screen.dart';
import '../presentation/main/profile_screen.dart';
import '../presentation/main/avatar_customizer_screen.dart';
import '../presentation/groups/create_group_screen.dart';
import '../presentation/main/snap_viewer_screen.dart';
import '../data/snap_repository.dart';
import '../presentation/splash/animated_splash_screen.dart';
import '../theme/colors.dart';

// Splash still uses fade route to avoid slide-in on app open
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
          builder: (context, state) => const AuthLandingScreen(),
        ),
        GoRoute(
          path: '/auth/email',
          builder: (context, state) => const AuthEmailScreen(),
        ),
        GoRoute(
          path: '/auth/username',
          builder: (context, state) => const UsernameSetupScreen(),
        ),
        GoRoute(
          path: '/auth/permissions',
          builder: (context, state) => const PermissionsScreen(),
        ),
        GoRoute(
          path: '/auth/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    ),

    // ── Main App ──
    GoRoute(
      path: '/main',
      builder: (context, state) => const CollectionsHomeScreen(),
      routes: [
        GoRoute(
          path: 'collections',
          builder: (context, state) => const CollectionsHomeScreen(),
        ),
        GoRoute(
          path: 'camera',
          builder: (context, state) => const CameraCaptureScreen(),
        ),
        GoRoute(
          path: 'send_to',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return SendToScreen(
              mediaPath: extra['mediaPath'] as String,
              isVideo: extra['isVideo'] as bool,
              caption: extra['caption'] as String?,
            );
          },
        ),
        GoRoute(
          path: 'snap_viewer',
          builder: (context, state) {
            final snaps = state.extra as List<DirectSnap>;
            return SnapViewerScreen(snaps: snaps);
          },
        ),
        GoRoute(
          path: 'daylog/:logId',
          builder: (context, state) {
            final logId = state.pathParameters['logId']!;
            final isClosed = state.uri.queryParameters['closed'] == 'true';
            return OwnLogViewerScreen(logId: logId, isClosed: isClosed);
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'avatar-customizer',
          builder: (context, state) => const AvatarCustomizerScreen(),
        ),
      ],
    ),

    // ── Friends & Social ──
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendsScreen(),
      routes: [
        GoRoute(
          path: 'create_group',
          builder: (context, state) => const CreateGroupScreen(),
        ),
        GoRoute(
          path: 'log/:shareId',
          builder: (context, state) {
            final shareId = state.pathParameters['shareId']!;
            return FriendLogViewerScreen(shareId: shareId);
          },
        ),
        GoRoute(
          path: 'add/:username',
          builder: (context, state) {
            final initialSearch = state.pathParameters['username'];
            return FriendsScreen(initialSearch: initialSearch);
          },
        ),
      ],
    ),
  ],
);
