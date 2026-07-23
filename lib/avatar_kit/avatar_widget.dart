import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dicebear_core/dicebear_core.dart' hide Color;
import 'package:dicebear_styles/avataaars.dart';
import 'momento_avatar.dart';
import '../theme/colors.dart';

/// Momento Avatar Widget
/// Uses official dicebear_core — 100% offline, no server calls, no internet needed.
/// Generates unique illustrated SVG avatars based on the MomentoAvatar configuration.
class AvatarWidget extends StatelessWidget {
  final MomentoAvatar avatar;
  final double size;
  final bool showBorder;
  final bool showGlow;

  const AvatarWidget({
    super.key,
    required this.avatar,
    this.size = 56,
    this.showBorder = false,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    // Generate avatar SVG offline with the fully mapped options
    final style = Style.parse(avataaars);
    final avatarData = Avatar(style, avatar.toMap());
    final svgString = avatarData.svg;

    Widget avatarWidget = ClipOval(
      child: SvgPicture.string(
        svgString,
        width: size,
        height: size,
      ),
    );

    if (showGlow) {
      final glowColor = Color(
        MomentoAvatar.bgGradients[avatar.bgScene][0],
      );
      avatarWidget = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: avatarWidget,
      );
    }

    if (showBorder) {
      return Container(
        width: size + 5,
        height: size + 5,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [SetlogColors.momentoPink, Color(0xFFE5366A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: avatarWidget),
      );
    }

    return avatarWidget;
  }
}
