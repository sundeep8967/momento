import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SetlogColors {
  // --- Momento Pink Brand Palette ---
  // Primary pink (matches mascot icon background ~#E87EA1)
  static const Color momentoPink        = Color(0xFFE8729A); // vibrant brand pink
  static const Color momentoPinkLight   = Color(0xFFF2A5BF); // soft hover/tint
  static const Color momentoPinkDark    = Color(0xFFBF4F75); // pressed/dark variant
  static const Color momentoPinkSurface = Color(0xFFFCEFF5); // ultra-light pink surface
  static const Color momentoPinkBorder  = Color(0xFFEFB8CF); // card border pink

  // Snap viewer accent: deep rose — like Snapchat red for "viewing a snap" state
  static const Color snapViewerAccent   = Color(0xFFE5366A);

  // Neutral iOS backgrounds
  static const Color authCanvas         = CupertinoColors.systemBackground;
  static const Color authSurface        = CupertinoColors.secondarySystemBackground;
  static const Color authSurfaceRaised  = CupertinoColors.tertiarySystemBackground;

  static const Color authInk            = CupertinoColors.label;
  static const Color authMuted          = CupertinoColors.secondaryLabel;
  static const Color authStrokeSoft     = momentoPinkBorder;

  // CTA & Buttons — all pink
  static const Color brownPrimary       = momentoPink;
  static const Color brownPrimaryDark   = momentoPinkDark;
  static const Color brownPrimaryText   = CupertinoColors.white;

  static const Color authButtonPrimary     = momentoPink;
  static const Color authButtonPrimaryText = CupertinoColors.white;
  static const Color authTerminalAccent    = momentoPink; // success = pink tick

  // Streak indicator — warm rose flame
  static const Color blueFlame  = Color(0xFFE5366A);
  static const Color authButter = Color(0xFFFFD6E7); // pastel pink-butter

  // --- Main App / Collections Colors ---
  static const Color collectionsHomeBackground     = Color(0xFFFDF4F8); // warm pinkish white
  static const Color collectionsHomeSurface        = CupertinoColors.systemBackground;
  static const Color collectionsHomeSurfacePressed = momentoPinkSurface;
  static const Color collectionsHomeTextPrimary    = CupertinoColors.label;
  static const Color collectionsHomeTextSecondary  = CupertinoColors.secondaryLabel;

  // --- Account Specific Colors (Profile Borders) ---
  static const Color accountBlue   = momentoPink;
  static const Color accountGreen  = Color(0xFFE5366A);
  static const Color accountOrange = momentoPinkLight;
  static const Color accountPink   = momentoPink;
  static const Color accountPurple = momentoPinkDark;

  // --- Camera UI ---
  static const Color cameraBackground    = Color(0xFF1A0A10); // near-black warm
  static const Color cameraTimerProgress = snapViewerAccent;
  static const Color cameraFocusRing     = momentoPinkLight;
}

final ThemeData setlogTheme = ThemeData(
  scaffoldBackgroundColor: SetlogColors.collectionsHomeBackground,
  primaryColor: SetlogColors.momentoPink,
  fontFamily: '.SF Pro Text',
  colorScheme: const ColorScheme.light(
    primary: SetlogColors.momentoPink,
    secondary: SetlogColors.momentoPinkLight,
    surface: SetlogColors.authSurface,
    onSurface: SetlogColors.authInk,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SetlogColors.collectionsHomeBackground,
    foregroundColor: SetlogColors.authInk,
    elevation: 0,
    iconTheme: IconThemeData(color: SetlogColors.momentoPink),
  ),
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: SetlogColors.momentoPink,
    scaffoldBackgroundColor: SetlogColors.collectionsHomeBackground,
    barBackgroundColor: SetlogColors.collectionsHomeBackground,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(fontFamily: '.SF Pro Text', color: SetlogColors.authInk),
    ),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
);
