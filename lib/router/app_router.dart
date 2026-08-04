import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../presentation/auth/auth_landing_screen.dart';
import '../presentation/auth/permissions_screen.dart';
import '../presentation/auth/auth_email_screen.dart';
import '../presentation/auth/username_setup_screen.dart';
import '../presentation/auth/avatar_setup_screen.dart';
import '../presentation/auth/onboarding_screen.dart';
import '../presentation/main/collections_home_screen.dart';
import '../presentation/main/camera_capture_screen.dart';
import '../presentation/main/send_to_screen.dart';
import '../presentation/main/friend_log_viewer_screen.dart';
import '../presentation/main/own_log_viewer_screen.dart';
import '../presentation/main/friends_screen.dart';
import '../presentation/main/profile_screen.dart';
import '../presentation/main/tea_screen.dart';
import '../presentation/main/chat_screen.dart';
import '../avatar_kit/avatar_kit_screen.dart';
import '../presentation/groups/create_group_screen.dart';
import '../presentation/main/snap_viewer_screen.dart';
import '../presentation/main/snap_map_screen.dart';
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


CustomTransitionPage<void> _fluidRoute(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: false,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
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
          pageBuilder: (context, state) => _fluidRoute(state, const AuthLandingScreen()),
        ),
        GoRoute(
          path: '/auth/email',
          pageBuilder: (context, state) => _fluidRoute(state, const AuthEmailScreen()),
        ),
        GoRoute(
          path: '/auth/username',
          pageBuilder: (context, state) => _fluidRoute(state, const UsernameSetupScreen()),
        ),
        GoRoute(
          path: '/auth/avatar-setup',
          pageBuilder: (context, state) => _fluidRoute(state, const AvatarSetupScreen()),
        ),
        GoRoute(
          path: '/auth/permissions',
          pageBuilder: (context, state) => _fluidRoute(state, const PermissionsScreen()),
        ),
        GoRoute(
          path: '/auth/onboarding',
          pageBuilder: (context, state) => _fluidRoute(state, const OnboardingScreen()),
        ),
      ],
    ),

    // ── Main App ──
    GoRoute(
      path: '/main',
      pageBuilder: (context, state) => _fluidRoute(state, const CollectionsHomeScreen()),
      routes: [
        GoRoute(
          path: 'collections',
          pageBuilder: (context, state) => _fluidRoute(state, const CollectionsHomeScreen()),
        ),
        GoRoute(
          path: 'camera',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final from = extra?['from'] as String? ?? state.uri.queryParameters['from'];
            return _fluidRoute(state, CameraCaptureScreen(from: from));
          },
        ),
        GoRoute(
          path: 'send_to',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return _fluidRoute(state, SendToScreen(
              mediaPath: extra['mediaPath'] as String,
              isVideo: extra['isVideo'] as bool,
              caption: extra['caption'] as String?,
              isFrontCamera: extra['isFrontCamera'] as bool? ?? false,
              from: extra['from'] as String?,
            ));
          },
        ),
        GoRoute(
          path: 'snap_viewer',
          pageBuilder: (context, state) {
            final snaps = state.extra as List<DirectSnap>;
            return _fluidRoute(state, SnapViewerScreen(snaps: snaps));
          },
        ),
        GoRoute(
          path: 'daylog/:logId',
          pageBuilder: (context, state) {
            final logId = state.pathParameters['logId']!;
            final isClosed = state.uri.queryParameters['closed'] == 'true';
            return _fluidRoute(state, OwnLogViewerScreen(logId: logId, isClosed: isClosed));
          },
        ),
        GoRoute(
          path: 'profile',
          pageBuilder: (context, state) => _fluidRoute(state, const ProfileScreen()),
        ),
        GoRoute(
          path: 'tea',
          pageBuilder: (context, state) => _fluidRoute(state, const TeaScreen()),
        ),
        GoRoute(
          path: 'avatar-customizer',
          // Redirected to avatar-kit — API-based screen removed, using offline SDK only
          pageBuilder: (context, state) => _fluidRoute(state, const AvatarKitScreen()),
        ),
        GoRoute(
          path: 'avatar-kit',
          pageBuilder: (context, state) => _fluidRoute(state, const AvatarKitScreen()),
        ),
      ],
    ),

    // ── Direct Messaging ──
    GoRoute(
      path: '/chat/:uid',
      pageBuilder: (context, state) {
        final uid = state.pathParameters['uid']!;
        return _fluidRoute(state, ChatScreen(uid: uid));
      },
    ),

    // ── Snap Map ──
    GoRoute(
      path: '/map',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _fluidRoute(state, SnapMapScreen(
          targetLat: extra?['targetLat'] as double?,
          targetLng: extra?['targetLng'] as double?,
        ));
      },
    ),

    // ── Friends & Social ──
    GoRoute(
      path: '/friends',
      pageBuilder: (context, state) => _fluidRoute(state, const FriendsScreen()),
      routes: [
        GoRoute(
          path: 'create_group',
          pageBuilder: (context, state) => _fluidRoute(state, const CreateGroupScreen()),
        ),
        GoRoute(
          path: 'log/:shareId',
          pageBuilder: (context, state) {
            final shareId = state.pathParameters['shareId']!;
            return _fluidRoute(state, FriendLogViewerScreen(shareId: shareId));
          },
        ),
        GoRoute(
          path: 'add/:username',
          pageBuilder: (context, state) {
            final initialSearch = state.pathParameters['username'];
            return _fluidRoute(state, FriendsScreen(initialSearch: initialSearch));
          },
        ),
      ],
    ),
  ],
);
