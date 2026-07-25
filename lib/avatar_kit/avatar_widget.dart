import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dicebear_core/dicebear_core.dart' hide Color;
import 'package:dicebear_styles/avataaars.dart';
import 'package:dicebear_styles/adventurer.dart';
import 'package:dicebear_styles/bottts.dart';
import 'package:dicebear_styles/fun_emoji.dart';
import 'package:dicebear_styles/pixel_art.dart';
import 'package:dicebear_styles/lorelei.dart';
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
    final svgString = _buildSvg();

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

  String _buildSvg() {
    switch (avatar.style) {
      case AvatarStyle.avataaars:
        return Avatar(Style.parse(avataaars), avatar.toMap()).svg;
      case AvatarStyle.adventurer:
        return Avatar(Style.parse(adventurer), {'seed': avatar.seed}).svg;
      case AvatarStyle.bottts:
        return Avatar(Style.parse(bottts), {'seed': avatar.seed}).svg;
      case AvatarStyle.funEmoji:
        return Avatar(Style.parse(funEmoji), {'seed': avatar.seed}).svg;
      case AvatarStyle.pixelArt:
        return Avatar(Style.parse(pixelArt), {'seed': avatar.seed}).svg;
      case AvatarStyle.lorelei:
        return Avatar(Style.parse(lorelei), {'seed': avatar.seed}).svg;
    }
  }
}
