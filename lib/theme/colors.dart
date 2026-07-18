import 'package:flutter/material.dart';

class SetlogColors {
  // --- Authentication Flow Colors ---
  static const Color authCanvas = Color(0xFFFFF6EE); // Main background
  static const Color authSurface = Color(0xFFFFFFFF);
  static const Color authSurfaceRaised = Color(0xFFF8F2EA);
  
  static const Color authInk = Color(0xFF1F1B18); // Primary Text
  static const Color authMuted = Color(0xFF665D56); // Secondary Text
  
  static const Color authButtonPrimary = Color(0xFF221C18);
  static const Color authButtonPrimaryText = Color(0xFFFFFBF5);
  
  static const Color authButter = Color(0xFFF5E19A); // Accent yellow
  static const Color authTerminalAccent = Color(0xFF65EA7B); // Success/Terminal green
  static const Color authStrokeSoft = Color(0x1F1F1B18); // Subtle borders

  // --- Main App / Collections Colors ---
  static const Color collectionsHomeBackground = authCanvas;
  static const Color collectionsHomeSurface = authSurface;
  static const Color collectionsHomeSurfacePressed = authSurfaceRaised;
  static const Color collectionsHomeTextPrimary = authInk;
  static const Color collectionsHomeTextSecondary = authMuted;
  
  // --- Account Specific Colors (Profile Borders) ---
  static const Color accountBlue = Color(0xFF11D5F3);
  static const Color accountGreen = Color(0xFF65EA7B);
  static const Color accountOrange = Color(0xFFFE9068);
  static const Color accountPink = Color(0xFFFE75F5);
  static const Color accountPurple = Color(0xFFAA6DFE);
  
  // --- Camera UI ---
  static const Color cameraBackground = Color(0xFF090909);
  static const Color cameraTimerProgress = accountGreen;
  static const Color cameraFocusRing = Color(0xFFFFD900);
}

final ThemeData setlogTheme = ThemeData(
  scaffoldBackgroundColor: SetlogColors.collectionsHomeBackground,
  primaryColor: SetlogColors.authInk,
  fontFamily: 'Inter', // Or any sans-serif to match the modern look
  
  colorScheme: const ColorScheme.light(
    primary: SetlogColors.authInk,
    secondary: SetlogColors.authTerminalAccent,
    surface: SetlogColors.authSurface,
    error: Color(0xFFB00020),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SetlogColors.authButtonPrimary,
      foregroundColor: SetlogColors.authButtonPrimaryText,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Soft rounded corners
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
  ),
);
