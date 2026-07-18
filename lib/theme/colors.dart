import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SetlogColors {
  // --- Core Monochrome Palette ---
  static const Color authCanvas = CupertinoColors.systemBackground;
  static const Color authSurface = CupertinoColors.secondarySystemBackground;
  static const Color authSurfaceRaised = CupertinoColors.tertiarySystemBackground;
  
  static const Color authInk = CupertinoColors.label;
  static const Color authMuted = CupertinoColors.secondaryLabel;
  
  static const Color brownPrimary = CupertinoColors.activeBlue; // Replace warm CTA with system blue
  static const Color brownPrimaryDark = Color(0xFF0055B3); 
  static const Color brownPrimaryText = CupertinoColors.white;

  static const Color authButtonPrimary = CupertinoColors.activeBlue;
  static const Color authButtonPrimaryText = CupertinoColors.white;
  
  static const Color authButter = CupertinoColors.systemYellow;
  static const Color authTerminalAccent = CupertinoColors.systemGreen; 
  static const Color authStrokeSoft = CupertinoColors.separator;

  // Blue flame (streak indicator)
  static const Color blueFlame = CupertinoColors.systemOrange;

  // --- Main App / Collections Colors ---
  static const Color collectionsHomeBackground = CupertinoColors.systemGroupedBackground;
  static const Color collectionsHomeSurface = CupertinoColors.secondarySystemGroupedBackground;
  static const Color collectionsHomeSurfacePressed = CupertinoColors.tertiarySystemGroupedBackground;
  static const Color collectionsHomeTextPrimary = CupertinoColors.label;
  static const Color collectionsHomeTextSecondary = CupertinoColors.secondaryLabel;
  
  // --- Account Specific Colors (Profile Borders) ---
  static const Color accountBlue = CupertinoColors.systemBlue;
  static const Color accountGreen = CupertinoColors.systemGreen;
  static const Color accountOrange = CupertinoColors.systemOrange;
  static const Color accountPink = CupertinoColors.systemPink;
  static const Color accountPurple = CupertinoColors.systemPurple;
  
  // --- Camera UI ---
  static const Color cameraBackground = CupertinoColors.black;
  static const Color cameraTimerProgress = CupertinoColors.systemRed;
  static const Color cameraFocusRing = CupertinoColors.systemYellow;
}

final ThemeData setlogTheme = ThemeData(
  scaffoldBackgroundColor: SetlogColors.collectionsHomeBackground,
  primaryColor: SetlogColors.brownPrimary,
  fontFamily: '.SF Pro Text', // Native iOS font
  colorScheme: const ColorScheme.light(
    primary: SetlogColors.brownPrimary,
    secondary: SetlogColors.authMuted,
    surface: SetlogColors.authSurface,
    onSurface: SetlogColors.authInk,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SetlogColors.collectionsHomeBackground,
    foregroundColor: SetlogColors.authInk,
    elevation: 0,
    iconTheme: IconThemeData(color: SetlogColors.authInk),
  ),
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: SetlogColors.brownPrimary,
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
