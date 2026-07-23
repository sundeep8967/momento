import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'momento_avatar.dart';

/// Momento Avatar Kit — CustomPainter Engine
/// Draws a fully layered Bitmoji-style character on a Canvas.
class AvatarPainter extends CustomPainter {
  final MomentoAvatar avatar;

  AvatarPainter(this.avatar);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawBackground(canvas, size);
    _drawBody(canvas, w, h);
    _drawHairBack(canvas, w, h);
    _drawEars(canvas, w, h);
    _drawFace(canvas, w, h);
    _drawEyebrows(canvas, w, h);
    _drawEyes(canvas, w, h);
    _drawNose(canvas, w, h);
    _drawMouth(canvas, w, h);
    if (avatar.facialHair > 0) _drawFacialHair(canvas, w, h);
    _drawHairFront(canvas, w, h);
    if (avatar.headwear > 0) _drawHeadwear(canvas, w, h);
    if (avatar.eyewear > 0) _drawEyewear(canvas, w, h);
  }

  // ─── Background ──────────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Size size) {
    final colors = MomentoAvatar.bgGradients[avatar.bgScene];
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Color(colors[0]), Color(colors[1])],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Floating pattern emojis (painted as repeating circles for offline mode)
    _drawBgPattern(canvas, size);
  }

  void _drawBgPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    const positions = [
      Offset(0.12, 0.15), Offset(0.88, 0.10), Offset(0.05, 0.75),
      Offset(0.85, 0.80), Offset(0.50, 0.05), Offset(0.30, 0.92),
      Offset(0.70, 0.88),
    ];
    for (final pos in positions) {
      canvas.drawCircle(
        Offset(size.width * pos.dx, size.height * pos.dy),
        size.width * 0.06,
        paint,
      );
    }
  }

  // ─── Body / Outfit ────────────────────────────────────────────────────────

  void _drawBody(Canvas canvas, double w, double h) {
    final outfitC = Color(MomentoAvatar.outfitColors[avatar.outfitColor]);
    final bodyTop = h * 0.74;
    final bodyPath = Path()
      ..moveTo(w * 0.18, h)
      ..lineTo(w * 0.18, bodyTop + h * 0.04)
      ..quadraticBezierTo(w * 0.22, bodyTop, w * 0.30, bodyTop)
      ..lineTo(w * 0.70, bodyTop)
      ..quadraticBezierTo(w * 0.78, bodyTop, w * 0.82, bodyTop + h * 0.04)
      ..lineTo(w * 0.82, h)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = outfitC);

    // Collar / neckline
    final neckPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final collarPath = Path()
      ..moveTo(w * 0.38, bodyTop)
      ..quadraticBezierTo(w * 0.50, bodyTop + h * 0.04, w * 0.62, bodyTop);
    canvas.drawPath(collarPath, neckPaint);

    // Outfit shadow
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 8),
    );
  }

  // ─── Ears ─────────────────────────────────────────────────────────────────

  void _drawEars(Canvas canvas, double w, double h) {
    final skinC = Color(MomentoAvatar.skinTones[avatar.skinTone]);
    final earPaint = Paint()..color = skinC;
    final innerEarPaint = Paint()
      ..color = Color(MomentoAvatar.skinTones[avatar.skinTone]).withValues(alpha: 0.6);

    // Left ear
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.215, h * 0.50), width: w * 0.08, height: h * 0.10), earPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.220, h * 0.50), width: w * 0.04, height: h * 0.06), innerEarPaint);

    // Right ear
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.785, h * 0.50), width: w * 0.08, height: h * 0.10), earPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.780, h * 0.50), width: w * 0.04, height: h * 0.06), innerEarPaint);
  }

  // ─── Face ─────────────────────────────────────────────────────────────────

  void _drawFace(Canvas canvas, double w, double h) {
    final skinC = Color(MomentoAvatar.skinTones[avatar.skinTone]);

    // Shadow under face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.52), width: w * 0.60, height: h * 0.56),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Face shape
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.50),
      width: w * 0.58,
      height: h * 0.54,
    );
    final faceRR = switch (avatar.faceShape) {
      1 => RRect.fromRectAndRadius(faceRect, const Radius.circular(999)), // oval
      2 => RRect.fromRectAndCorners(faceRect, // heart-ish
          topLeft: const Radius.circular(50),
          topRight: const Radius.circular(50),
          bottomLeft: const Radius.circular(120),
          bottomRight: const Radius.circular(120)),
      3 => RRect.fromRectAndRadius(faceRect, const Radius.circular(16)), // square
      _ => RRect.fromRectAndRadius(faceRect, const Radius.circular(120)), // round (default)
    };
    canvas.drawRRect(faceRR, Paint()..color = skinC);

    // Cheek blush
    final blushPaint = Paint()
      ..color = const Color(0xFFE8729A).withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(w * 0.30, h * 0.57), w * 0.08, blushPaint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.57), w * 0.08, blushPaint);

    // Face highlight (3D gloss)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.40), width: w * 0.20, height: h * 0.12),
      highlightPaint,
    );
  }

  // ─── Eyebrows ─────────────────────────────────────────────────────────────

  void _drawEyebrows(Canvas canvas, double w, double h) {
    final browColor = Color(MomentoAvatar.hairColors[avatar.hairColor]);
    final strokeWidth = switch (avatar.browStyle) {
      1 => 5.5, // thick
      2 => 2.0, // thin
      _ => 3.5,
    };
    final paint = Paint()
      ..color = browColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final yBase = h * 0.40;
    final curve = avatar.browStyle == 3 ? h * 0.025 : h * 0.012;

    // Left brow
    final leftBrow = Path()
      ..moveTo(w * 0.32, yBase)
      ..quadraticBezierTo(w * 0.37, yBase - curve, w * 0.43, yBase + (avatar.browStyle == 3 ? h * 0.008 : 0));
    canvas.drawPath(leftBrow, paint);

    // Right brow
    final rightBrow = Path()
      ..moveTo(w * 0.57, yBase + (avatar.browStyle == 3 ? h * 0.008 : 0))
      ..quadraticBezierTo(w * 0.63, yBase - curve, w * 0.68, yBase);
    canvas.drawPath(rightBrow, paint);
  }

  // ─── Eyes ─────────────────────────────────────────────────────────────────

  void _drawEyes(Canvas canvas, double w, double h) {
    _drawSingleEye(canvas, w * 0.375, h * 0.47, w, h, isLeft: true);
    _drawSingleEye(canvas, w * 0.625, h * 0.47, w, h, isLeft: false);
  }

  void _drawSingleEye(Canvas canvas, double cx, double cy, double w, double h, {required bool isLeft}) {
    final ew = w * 0.12;
    final eh = switch (avatar.eyeStyle) {
      2 => h * 0.09, // wide
      3 => h * 0.04, // sleepy
      4 => h * 0.10, // anime
      _ => h * 0.07, // default
    };

    // White of eye
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: ew, height: eh),
      Paint()..color = Colors.white,
    );

    // Iris
    canvas.drawCircle(
      Offset(cx, cy),
      eh * 0.42,
      Paint()..color = const Color(0xFF3E2723),
    );

    // Pupil
    canvas.drawCircle(
      Offset(cx, cy),
      eh * 0.22,
      Paint()..color = Colors.black,
    );

    // Catchlight highlight
    canvas.drawCircle(
      Offset(cx - ew * 0.10, cy - eh * 0.18),
      eh * 0.12,
      Paint()..color = Colors.white,
    );

    // Eyelash line
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: ew, height: eh),
      math.pi, math.pi,
      false,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Anime sparkle extra iris ring
    if (avatar.eyeStyle == 4) {
      canvas.drawCircle(
        Offset(cx, cy),
        eh * 0.44,
        Paint()
          ..color = const Color(0xFFE8729A).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  // ─── Nose ─────────────────────────────────────────────────────────────────

  void _drawNose(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Color(MomentoAvatar.skinTones[avatar.skinTone]).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final nosePath = Path()
      ..moveTo(w * 0.46, h * 0.52)
      ..quadraticBezierTo(w * 0.44, h * 0.57, w * 0.46, h * 0.59)
      ..quadraticBezierTo(w * 0.50, h * 0.61, w * 0.54, h * 0.59)
      ..quadraticBezierTo(w * 0.56, h * 0.57, w * 0.54, h * 0.52);
    canvas.drawPath(nosePath, paint);
  }

  // ─── Mouth ────────────────────────────────────────────────────────────────

  void _drawMouth(Canvas canvas, double w, double h) {
    final mouthPaint = Paint()
      ..color = const Color(0xFFB5174A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final yCenter = h * 0.67;

    switch (avatar.mouthStyle) {
      case 1: // Big smile with teeth
        final smilePath = Path()
          ..moveTo(w * 0.36, yCenter)
          ..quadraticBezierTo(w * 0.50, yCenter + h * 0.06, w * 0.64, yCenter);
        canvas.drawPath(smilePath, mouthPaint..strokeWidth = 3.5);
        // Teeth
        canvas.drawArc(
          Rect.fromCenter(center: Offset(w * 0.50, yCenter + h * 0.01), width: w * 0.26, height: h * 0.06),
          0, math.pi,
          true,
          Paint()..color = Colors.white,
        );
        break;
      case 2: // Smirk
        final smirkPath = Path()
          ..moveTo(w * 0.42, yCenter + h * 0.01)
          ..quadraticBezierTo(w * 0.52, yCenter - h * 0.01, w * 0.60, yCenter - h * 0.01);
        canvas.drawPath(smirkPath, mouthPaint);
        break;
      case 3: // Open/surprised
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.50, yCenter + h * 0.01), width: w * 0.12, height: h * 0.055),
          Paint()..color = const Color(0xFFB5174A),
        );
        break;
      default: // Smile
        final smilePath = Path()
          ..moveTo(w * 0.40, yCenter)
          ..quadraticBezierTo(w * 0.50, yCenter + h * 0.04, w * 0.60, yCenter);
        canvas.drawPath(smilePath, mouthPaint);
    }
  }

  // ─── Facial Hair ──────────────────────────────────────────────────────────

  void _drawFacialHair(Canvas canvas, double w, double h) {
    final hairC = Color(MomentoAvatar.hairColors[avatar.hairColor]);
    final paint = Paint()..color = hairC.withValues(alpha: 0.85);

    switch (avatar.facialHair) {
      case 1: // Full beard
        final beardPath = Path()
          ..moveTo(w * 0.28, h * 0.62)
          ..quadraticBezierTo(w * 0.25, h * 0.74, w * 0.35, h * 0.77)
          ..lineTo(w * 0.65, h * 0.77)
          ..quadraticBezierTo(w * 0.75, h * 0.74, w * 0.72, h * 0.62)
          ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.28, h * 0.62)
          ..close();
        canvas.drawPath(beardPath, paint);
        break;
      case 2: // Goatee
        final goateePath = Path()
          ..moveTo(w * 0.42, h * 0.66)
          ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.58, h * 0.66)
          ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.42, h * 0.66)
          ..close();
        canvas.drawPath(goateePath, paint);
        break;
      case 3: // Mustache
        final mustachePath = Path()
          ..moveTo(w * 0.38, h * 0.64)
          ..quadraticBezierTo(w * 0.44, h * 0.67, w * 0.50, h * 0.63)
          ..quadraticBezierTo(w * 0.56, h * 0.67, w * 0.62, h * 0.64)
          ..quadraticBezierTo(w * 0.50, h * 0.69, w * 0.38, h * 0.64)
          ..close();
        canvas.drawPath(mustachePath, paint);
        break;
    }
  }

  // ─── Hair ─────────────────────────────────────────────────────────────────

  void _drawHairBack(Canvas canvas, double w, double h) {
    // Only long + buns have a back layer
    if (avatar.hairStyle == 1 || avatar.hairStyle == 3) {
      _drawHairLayer(canvas, w, h, isBack: true);
    }
  }

  void _drawHairFront(Canvas canvas, double w, double h) {
    if (avatar.hairStyle == 4) return; // bald
    _drawHairLayer(canvas, w, h, isBack: false);
  }

  void _drawHairLayer(Canvas canvas, double w, double h, {required bool isBack}) {
    final hairC = Color(MomentoAvatar.hairColors[avatar.hairColor]);
    final paint = Paint()..color = hairC;
    final darkPaint = Paint()..color = hairC.withValues(alpha: 0.65);

    switch (avatar.hairStyle) {
      case 0: // Short fade
        if (!isBack) {
          final path = Path()
            ..moveTo(w * 0.24, h * 0.42)
            ..quadraticBezierTo(w * 0.24, h * 0.22, w * 0.50, h * 0.20)
            ..quadraticBezierTo(w * 0.76, h * 0.22, w * 0.76, h * 0.42)
            ..quadraticBezierTo(w * 0.68, h * 0.36, w * 0.50, h * 0.34)
            ..quadraticBezierTo(w * 0.32, h * 0.36, w * 0.24, h * 0.42)
            ..close();
          canvas.drawPath(path, paint);
          // Fade highlight
          canvas.drawPath(path, Paint()
            ..shader = LinearGradient(
              colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromLTWH(0, h * 0.20, w, h * 0.22)));
        }
        break;

      case 1: // Long straight
        if (isBack) {
          // Long side panels
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.18, h * 0.26, w * 0.29, h * 0.78), const Radius.circular(12)),
            darkPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.71, h * 0.26, w * 0.82, h * 0.78), const Radius.circular(12)),
            darkPaint,
          );
        } else {
          final path = Path()
            ..moveTo(w * 0.24, h * 0.42)
            ..quadraticBezierTo(w * 0.24, h * 0.22, w * 0.50, h * 0.19)
            ..quadraticBezierTo(w * 0.76, h * 0.22, w * 0.76, h * 0.42)
            ..quadraticBezierTo(w * 0.68, h * 0.35, w * 0.50, h * 0.33)
            ..quadraticBezierTo(w * 0.32, h * 0.35, w * 0.24, h * 0.42)
            ..close();
          canvas.drawPath(path, paint);
        }
        break;

      case 2: // Curly afro
        if (!isBack) {
          final center = Offset(w * 0.50, h * 0.28);
          final afroPaint = Paint()..color = hairC;
          // Big poofy cloud of circles
          for (int i = 0; i < 12; i++) {
            final angle = (i / 12) * math.pi * 2;
            final r = h * 0.145;
            canvas.drawCircle(
              Offset(center.dx + math.cos(angle) * r * 0.65,
                     center.dy + math.sin(angle) * r * 0.5),
              r * 0.55,
              afroPaint,
            );
          }
          // Central dome
          canvas.drawCircle(center, h * 0.13, afroPaint);
        }
        break;

      case 3: // Double buns
        if (isBack) {
          canvas.drawCircle(Offset(w * 0.33, h * 0.24), h * 0.085, darkPaint);
          canvas.drawCircle(Offset(w * 0.67, h * 0.24), h * 0.085, darkPaint);
        } else {
          canvas.drawCircle(Offset(w * 0.33, h * 0.23), h * 0.08, paint);
          canvas.drawCircle(Offset(w * 0.67, h * 0.23), h * 0.08, paint);
          // Band
          final bandPath = Path()
            ..moveTo(w * 0.24, h * 0.40)
            ..quadraticBezierTo(w * 0.24, h * 0.25, w * 0.50, h * 0.24)
            ..quadraticBezierTo(w * 0.76, h * 0.25, w * 0.76, h * 0.40)
            ..quadraticBezierTo(w * 0.68, h * 0.35, w * 0.50, h * 0.33)
            ..quadraticBezierTo(w * 0.32, h * 0.35, w * 0.24, h * 0.40)
            ..close();
          canvas.drawPath(bandPath, paint);
        }
        break;

      case 5: // Spiky
        if (!isBack) {
          // Base
          final basePath = Path()
            ..moveTo(w * 0.26, h * 0.42)
            ..quadraticBezierTo(w * 0.26, h * 0.28, w * 0.50, h * 0.26)
            ..quadraticBezierTo(w * 0.74, h * 0.28, w * 0.74, h * 0.42)
            ..close();
          canvas.drawPath(basePath, paint);
          // Spikes
          for (int i = 0; i < 5; i++) {
            final x = w * (0.30 + i * 0.10);
            final spikyPath = Path()
              ..moveTo(x - w * 0.04, h * 0.30)
              ..lineTo(x, h * 0.12 - i % 2 * h * 0.04)
              ..lineTo(x + w * 0.04, h * 0.30)
              ..close();
            canvas.drawPath(spikyPath, paint);
          }
        }
        break;
    }
  }

  // ─── Headwear ─────────────────────────────────────────────────────────────

  void _drawHeadwear(Canvas canvas, double w, double h) {
    switch (avatar.headwear) {
      case 1: _drawCap(canvas, w, h); break;
      case 2: _drawBeanie(canvas, w, h); break;
      case 3: _drawCrown(canvas, w, h); break;
      case 4: _drawHalo(canvas, w, h); break;
    }
  }

  void _drawCap(Canvas canvas, double w, double h) {
    final capColor = const Color(0xFFE8729A); // Momento pink
    // Dome
    final domePath = Path()
      ..moveTo(w * 0.24, h * 0.36)
      ..quadraticBezierTo(w * 0.24, h * 0.16, w * 0.50, h * 0.14)
      ..quadraticBezierTo(w * 0.76, h * 0.16, w * 0.76, h * 0.36)
      ..close();
    canvas.drawPath(domePath, Paint()..color = capColor);

    // Brim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.22, h * 0.33, w * 0.82, h * 0.40),
        const Radius.circular(6),
      ),
      Paint()..color = capColor.withValues(alpha: 0.85),
    );

    // Button on top
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.03, Paint()..color = Colors.white.withValues(alpha: 0.6));

    // Visor edge shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.22, h * 0.36, w * 0.82, h * 0.39),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
  }

  void _drawBeanie(Canvas canvas, double w, double h) {
    final beanieColor = const Color(0xFFFFB300);
    // Body
    final path = Path()
      ..moveTo(w * 0.24, h * 0.38)
      ..quadraticBezierTo(w * 0.24, h * 0.18, w * 0.50, h * 0.16)
      ..quadraticBezierTo(w * 0.76, h * 0.18, w * 0.76, h * 0.38)
      ..close();
    canvas.drawPath(path, Paint()..color = beanieColor);

    // Ribbing stripes
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 3;
    for (double y = h * 0.20; y < h * 0.38; y += h * 0.04) {
      canvas.drawLine(Offset(w * 0.28, y), Offset(w * 0.72, y), stripePaint);
    }

    // Pom pom
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.06, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.04, Paint()..color = beanieColor.withValues(alpha: 0.5));
  }

  void _drawCrown(Canvas canvas, double w, double h) {
    final goldPaint = Paint()..color = const Color(0xFFFFD700);
    // Base band
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.26, h * 0.28, w * 0.74, h * 0.38), const Radius.circular(4)),
      goldPaint,
    );

    // Crown spikes
    final spikes = [
      [w * 0.30, h * 0.28, w * 0.36, h * 0.14, w * 0.42, h * 0.28],
      [w * 0.44, h * 0.28, w * 0.50, h * 0.10, w * 0.56, h * 0.28],
      [w * 0.58, h * 0.28, w * 0.64, h * 0.14, w * 0.70, h * 0.28],
    ];
    for (final s in spikes) {
      canvas.drawPath(
        Path()
          ..moveTo(s[0], s[1])
          ..lineTo(s[2], s[3])
          ..lineTo(s[4], s[5])
          ..close(),
        goldPaint,
      );
    }

    // Jewels on crown
    final jewelColors = [Colors.red, Colors.blue, Colors.green];
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.33 + i * 0.17), h * 0.32),
        w * 0.025,
        Paint()..color = jewelColors[i],
      );
    }
  }

  void _drawHalo(Canvas canvas, double w, double h) {
    final haloPaint = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.14), width: w * 0.35, height: h * 0.07),
      haloPaint,
    );
  }

  // ─── Eyewear ──────────────────────────────────────────────────────────────

  void _drawEyewear(Canvas canvas, double w, double h) {
    switch (avatar.eyewear) {
      case 1: _drawSunglasses(canvas, w, h); break;
      case 2: _drawGlasses(canvas, w, h); break;
      case 3: _drawHeadphones(canvas, w, h); break;
    }
  }

  void _drawSunglasses(Canvas canvas, double w, double h) {
    final lensPaint = Paint()..color = const Color(0xFF1A1A1A).withValues(alpha: 0.88);
    final framePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Left lens
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.375, h * 0.47), width: w * 0.16, height: h * 0.09), lensPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.375, h * 0.47), width: w * 0.16, height: h * 0.09), framePaint);

    // Right lens
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.625, h * 0.47), width: w * 0.16, height: h * 0.09), lensPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.625, h * 0.47), width: w * 0.16, height: h * 0.09), framePaint);

    // Bridge
    canvas.drawLine(Offset(w * 0.455, h * 0.47), Offset(w * 0.545, h * 0.47),
        Paint()..color = Colors.black..strokeWidth = 2.5);

    // Temple arms
    canvas.drawLine(Offset(w * 0.215, h * 0.47), Offset(w * 0.295, h * 0.47),
        Paint()..color = Colors.black..strokeWidth = 2.5);
    canvas.drawLine(Offset(w * 0.705, h * 0.47), Offset(w * 0.785, h * 0.47),
        Paint()..color = Colors.black..strokeWidth = 2.5);

    // Lens glare
    canvas.drawLine(
      Offset(w * 0.345, h * 0.44), Offset(w * 0.365, h * 0.46),
      Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 2..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(w * 0.595, h * 0.44), Offset(w * 0.615, h * 0.46),
      Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 2..strokeCap = StrokeCap.round,
    );
  }

  void _drawGlasses(Canvas canvas, double w, double h) {
    final framePaint = Paint()
      ..color = const Color(0xFF4A2C2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.375, h * 0.47), width: w * 0.17, height: h * 0.09), const Radius.circular(6)),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.625, h * 0.47), width: w * 0.17, height: h * 0.09), const Radius.circular(6)),
      framePaint,
    );
    canvas.drawLine(Offset(w * 0.458, h * 0.47), Offset(w * 0.542, h * 0.47),
        Paint()..color = const Color(0xFF4A2C2A)..strokeWidth = 3);
    canvas.drawLine(Offset(w * 0.205, h * 0.47), Offset(w * 0.287, h * 0.47),
        framePaint..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(w * 0.713, h * 0.47), Offset(w * 0.795, h * 0.47),
        framePaint..style = PaintingStyle.stroke);
  }

  void _drawHeadphones(Canvas canvas, double w, double h) {
    final hpPaint = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    // Arc over head
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.30), width: w * 0.60, height: h * 0.30),
      math.pi, math.pi, false, hpPaint,
    );

    // Ear cups
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.20, h * 0.45), width: w * 0.10, height: h * 0.12),
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.80, h * 0.45), width: w * 0.10, height: h * 0.12),
      Paint()..color = const Color(0xFF212121),
    );

    // Cup highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.20, h * 0.44), width: w * 0.05, height: h * 0.06),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.80, h * 0.44), width: w * 0.05, height: h * 0.06),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(AvatarPainter oldDelegate) => oldDelegate.avatar != avatar;

  @override
  bool operator ==(Object other) =>
      other is AvatarPainter && other.avatar.toJson().toString() == avatar.toJson().toString();

  @override
  int get hashCode => avatar.toJson().toString().hashCode;
}
