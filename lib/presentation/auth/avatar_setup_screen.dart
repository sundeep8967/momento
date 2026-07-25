import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../avatar_kit/avatar_kit_screen.dart';
import '../../avatar_kit/avatar_widget.dart';
import '../../avatar_kit/momento_avatar.dart';
import '../../data/friends_repository.dart';
import '../../theme/colors.dart';

class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({super.key});

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen>
    with SingleTickerProviderStateMixin {
  late MomentoAvatar _avatar;
  AvatarStyle _selectedStyle = AvatarStyle.avataaars;
  bool _isSaving = false;
  late AnimationController _bounceCtrl;
  final _rng = Random();

  // Style catalogue shown in the picker
  static const _styles = [
    (style: AvatarStyle.avataaars, emoji: '🧑', label: 'Human'),
    (style: AvatarStyle.adventurer, emoji: '🐾', label: 'Animal'),
    (style: AvatarStyle.bottts, emoji: '🤖', label: 'Bot'),
    (style: AvatarStyle.funEmoji, emoji: '😄', label: 'Fun'),
    (style: AvatarStyle.pixelArt, emoji: '🎨', label: 'Pixel'),
    (style: AvatarStyle.lorelei, emoji: '👤', label: 'Minimal'),
  ];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _avatar = MomentoAvatar.fromSeed(uid);
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _shuffle() {
    final newSeed = _rng.nextInt(999999).toString();
    setState(() {
      if (_selectedStyle == AvatarStyle.avataaars) {
        _avatar = MomentoAvatar.fromSeed(newSeed);
      } else {
        _avatar = MomentoAvatar.fromSeedAndStyle(newSeed, _selectedStyle);
      }
    });
    _bounceCtrl.forward(from: 0);
  }

  void _onStyleChanged(AvatarStyle style) {
    final seed = _avatar.seed;
    setState(() {
      _selectedStyle = style;
      if (style == AvatarStyle.avataaars) {
        _avatar = MomentoAvatar.fromSeed(seed);
      } else {
        _avatar = MomentoAvatar.fromSeedAndStyle(seed, style);
      }
    });
    _bounceCtrl.forward(from: 0);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final avatarJson = jsonEncode(_avatar.toJson());
      await FriendsRepository.instance
          .updateProfilePicture('avatar:$avatarJson');
      if (mounted) context.go('/auth/permissions');
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _openCustomizer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AvatarKitScreen()),
    );
    // Reload whatever the customizer saved to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final profile = await FriendsRepository.instance.getUserProfile(uid);
    if (profile?.avatar != null && mounted) {
      setState(() => _avatar = profile!.avatar!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = MomentoAvatar.bgGradients[_avatar.bgScene];

    return Scaffold(
      backgroundColor: SetlogColors.authCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Avatar',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: Color(0xFF1A0A10),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick a style and shuffle until you love it.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF7A4A60),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

            // ── Avatar Preview ──────────────────────────────────────
            Expanded(
              flex: 4,
              child: Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _bounceCtrl,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(gradientColors[0]),
                          Color(gradientColors[1]),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(gradientColors[1]).withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: AvatarWidget(
                      avatar: _avatar,
                      size: 198,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

            // ── Style Tabs ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _styles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final s = _styles[i];
                    final isSelected = _selectedStyle == s.style;
                    return GestureDetector(
                      onTap: () => _onStyleChanged(s.style),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: 72,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SetlogColors.momentoPink
                              : const Color(0xFFF7EEF3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? SetlogColors.momentoPink
                                : const Color(0xFFEFB8CF),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: SetlogColors.momentoPink
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF7A4A60),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

            const SizedBox(height: 20),

            // ── Action Buttons ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shuffle button
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _shuffle,
                    icon: const Text('🎲', style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'Shuffle',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: SetlogColors.momentoPink,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: SetlogColors.momentoPink, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  // Customize button — only for Human (avataaars) style
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: _selectedStyle == AvatarStyle.avataaars
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _openCustomizer,
                              icon: const Text('✏️',
                                  style: TextStyle(fontSize: 18)),
                              label: const Text(
                                'Customize',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF7A4A60),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFEFB8CF), width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Save & Continue
                  CupertinoButton(
                    onPressed: _isSaving ? null : _save,
                    color: SetlogColors.momentoPink,
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'Save & Continue →',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  // Skip
                  Center(
                    child: TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => context.go('/auth/permissions'),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Color(0xFF7A4A60),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.2),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
