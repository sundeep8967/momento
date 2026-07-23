import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:momento/data/snap_repository.dart';
import 'package:momento/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../avatar_kit/avatar_widget.dart';
import '../../avatar_kit/momento_avatar.dart';
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/smoking_mode_provider.dart';

class CollectionsHomeScreen extends ConsumerStatefulWidget {
  const CollectionsHomeScreen({super.key});

  @override
  ConsumerState<CollectionsHomeScreen> createState() => _CollectionsHomeScreenState();
}

class _CollectionsHomeScreenState extends ConsumerState<CollectionsHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final snapRepo = ref.read(snapRepositoryProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      bottomNavigationBar: _buildFloatingBottomBar(context),
      body: StreamBuilder<List<DirectSnap>>(
        stream: snapRepo.getInboxStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final allSnaps = snapshot.data ?? [];

          // Group snaps by senderUid or groupName
          final Map<String, List<DirectSnap>> grouped = {};
          for (final snap in allSnaps) {
            final key = snap.groupName != null && snap.groupName!.isNotEmpty
                ? 'group:${snap.groupName}'
                : snap.senderUid;
            grouped.putIfAbsent(key, () => []).add(snap);
          }

          final entries = grouped.values.toList();
          entries.sort((a, b) {
            final aNew = a.any((s) => !s.isViewed && s.senderUid != currentUid);
            final bNew = b.any((s) => !s.isViewed && s.senderUid != currentUid);
            if (aNew != bNew) return aNew ? -1 : 1;
            return b.first.timestamp.compareTo(a.first.timestamp);
          });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom Header
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left 3D Avatar Profile Button
                        GestureDetector(
                          onTap: () => context.push('/main/profile'),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF4F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: SetlogColors.momentoPinkBorder, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: SetlogColors.momentoPink.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        // Title "Momento" (British Handwriting Style - Offline Native)
                        const Text(
                          'Momento',
                          style: TextStyle(
                            fontFamily: 'Snell Roundhand',
                            fontFamilyFallback: [
                              'Bradley Hand',
                              'Dancing Script',
                              'Great Vibes',
                              'cursive',
                            ],
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),

                        // Right Actions: Search & Add Friend Buttons
                        Row(
                          children: [
                            // Search Button
                            GestureDetector(
                              onTap: () => context.push('/friends'),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFEAEAEA)),
                                ),
                                child: const Icon(CupertinoIcons.search, color: Colors.black, size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Momento Pink Add Friend Button
                            GestureDetector(
                              onTap: () => context.push('/friends'),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: SetlogColors.momentoPink,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SetlogColors.momentoPink.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(CupertinoIcons.person_badge_plus, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Chat Cards List
              if (entries.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate(_buildStaticSampleCards()),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final userSnaps = entries[index];
                      userSnaps.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      final snap = userSnaps.first;
                      final isMe = snap.senderUid == currentUid;
                      final unreadCount = userSnaps.where((s) => !s.isViewed && s.senderUid != currentUid).length;
                      final isNew = unreadCount > 0 && !isMe;
                      final snapColor = snap.isVideo ? const Color(0xFFAB47BC) : SetlogColors.momentoPink;
                      final displayName = snap.groupName != null && snap.groupName!.isNotEmpty
                          ? snap.groupName!
                          : snap.senderUsername;

                      return GestureDetector(
                        onTap: () {
                          if (!isMe) {
                            context.push('/main/snap_viewer', extra: {'snaps': userSnaps, 'initialIndex': 0});
                          } else {
                            context.push('/main/snap_viewer', extra: {'snaps': userSnaps, 'initialIndex': 0});
                          }
                        },
                        child: ChatCardItem(
                          name: displayName,
                          status: isNew ? 'NEW SNAP • TAP TO VIEW' : (isMe ? 'Delivered' : 'Received'),
                          statusColor: isNew ? SetlogColors.snapViewerAccent : const Color(0xFF666666),
                          time: timeago.format(snap.timestamp, locale: 'en_short').toUpperCase(),
                          streak: unreadCount > 0 ? unreadCount : null,
                          avatarSeed: displayName,
                          isOpened: !isNew && !isMe,
                          isDelivered: isMe,
                          isNew: isNew,
                          isVideo: snap.isVideo,
                        ),
                      );
                    },
                    childCount: entries.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Pill
          Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Row(
                  children: [
                    // Chat Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {}, // Already here
                        child: const Icon(CupertinoIcons.chat_bubble_fill, color: SetlogColors.momentoPink, size: 28),
                      ),
                    ),
                    // Spacer for central camera
                    const SizedBox(width: 80),
                    // Friends Tab (Now Tea or Smoking Icon)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/main/tea'),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final isSmokingMode = ref.watch(smokingModeProvider);
                            return Icon(
                              isSmokingMode ? Icons.smoking_rooms : Icons.emoji_food_beverage_outlined,
                              color: const Color(0xFF8E8E93),
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Protruding Camera Button
          Positioned(
            bottom: 15,
            child: GestureDetector(
              onTap: () => context.push('/main/camera'),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: 0.15, // Rotate right slightly
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: SetlogColors.momentoPink,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: SetlogColors.momentoPink.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(CupertinoIcons.camera, color: Colors.white, size: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStaticSampleCards() {
    return const [
      ChatCardItem(
        name: 'Chloe Miller',
        status: 'NEW SNAP • TAP TO VIEW',
        statusColor: SetlogColors.snapViewerAccent,
        time: '2M',
        avatarSeed: 'Chloe',
        isNew: true,
        isVideo: false,
      ),
      ChatCardItem(
        name: 'Alex Rivera',
        status: 'Delivered',
        statusColor: Color(0xFF666666),
        time: '14M',
        avatarSeed: 'Alex',
        isDelivered: true,
        isNew: false,
        isVideo: false,
      ),
      ChatCardItem(
        name: 'Jordan Wu',
        status: 'Opened',
        statusColor: Color(0xFF888888),
        time: '1H',
        avatarSeed: 'Jordan',
        isOpened: true,
        isNew: false,
        isVideo: false,
      ),
      ChatCardItem(
        name: 'Sarah Jenkins',
        status: 'Received • Chat',
        statusColor: Color(0xFF007AFF),
        time: '3H',
        avatarSeed: 'Sarah',
        isOpened: false,
        isNew: false,
        isVideo: false,
        isChatReceived: true,
      ),
      ChatCardItem(
        name: 'Liam Tech',
        status: 'Received • Snap',
        statusColor: SetlogColors.snapViewerAccent,
        time: '4H',
        streak: 24,
        avatarSeed: 'Liam',
        isOpened: false,
        isNew: false,
        isVideo: true,
      ),
      ChatCardItem(
        name: 'Mia Sunshine',
        status: 'Opened',
        statusColor: Color(0xFF888888),
        time: 'YESTERDAY',
        avatarSeed: 'Mia',
        isOpened: true,
        isNew: false,
        isVideo: false,
      ),
    ];
  }
}

class ChatCardItem extends StatelessWidget {
  final String name;
  final String status;
  final Color statusColor;
  final String time;
  final int? streak;
  final String avatarSeed;
  final String? avatarUrl;
  final bool isOpened;
  final bool isDelivered;
  final bool isNew;
  final bool isVideo;
  final bool isChatReceived;

  const ChatCardItem({
    super.key,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.time,
    this.streak,
    required this.avatarSeed,
    this.avatarUrl,
    this.isOpened = false,
    this.isDelivered = false,
    this.isNew = false,
    this.isVideo = false,
    this.isChatReceived = false,
  });

  @override
  Widget build(BuildContext context) {
    MomentoAvatar displayAvatar = MomentoAvatar.fromSeed(avatarSeed);
    if (avatarUrl != null && avatarUrl!.startsWith('avatar:')) {
      try {
        final map = jsonDecode(avatarUrl!.substring(7));
        displayAvatar = MomentoAvatar(
          seed: map['seed'] ?? avatarSeed,
          skinColor: map['skinColor'] ?? 'ffdbb4',
          top: map['top'] ?? 'shortHair',
          hairColor: map['hairColor'] ?? '2c1b18',
          hatColor: map['hatColor'] ?? '2c1b18',
          accessories: map['accessories'] ?? 'none',
          accessoriesColor: map['accessoriesColor'] ?? '262e33',
          facialHair: map['facialHair'] ?? 'none',
          facialHairColor: map['facialHairColor'] ?? '2c1b18',
          clothes: map['clothes'] ?? 'blazerAndShirt',
          clothesColor: map['clothesColor'] ?? 'ffffff',
          clothesGraphic: map['clothesGraphic'] ?? 'none',
          eyes: map['eyes'] ?? 'default',
          eyebrows: map['eyebrows'] ?? 'default',
          mouth: map['mouth'] ?? 'default',
          bgScene: map['bgScene'] ?? 0,
        );
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar container with optional Glowing Momento Pink Border for New Snaps
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: isNew
                  ? Border.all(color: SetlogColors.momentoPink, width: 3)
                  : null,
              boxShadow: isNew
                  ? [
                      BoxShadow(
                        color: SetlogColors.momentoPink.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isNew ? 15 : 18),
              child: AvatarWidget(
                avatar: displayAvatar,
                size: 56,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name, Status & Streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (streak != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 2),
                            Text(
                              '$streak',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusIndicator(),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: isNew ? FontWeight.w900 : FontWeight.w600,
                          letterSpacing: isNew ? 0.3 : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Timestamp
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (isNew) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: SetlogColors.momentoPink,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    } else if (isDelivered) {
      return const Icon(CupertinoIcons.location_fill, color: Color(0xFF8E8E93), size: 14);
    } else if (isChatReceived) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    } else if (isVideo) {
      return const Icon(CupertinoIcons.play_circle_fill, color: SetlogColors.momentoPink, size: 14);
    } else {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          border: Border.all(color: SetlogColors.momentoPink, width: 2),
          shape: BoxShape.circle,
        ),
      );
    }
  }
}

class Snapchat3DAvatarWidget extends StatelessWidget {
  final String seed;
  final String? avatarUrl;
  final double size;

  const Snapchat3DAvatarWidget({
    super.key,
    required this.seed,
    this.avatarUrl,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.startsWith('assets/')) {
      return Image.asset(avatarUrl!, fit: BoxFit.cover);
    }

    if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildOffline3DAvatar(),
      );
    }

    return _buildOffline3DAvatar();
  }

  Widget _buildOffline3DAvatar() {
    final hash = seed.hashCode.abs();
    final avatarAssets = [
      'assets/avatars/avatar_1.png',
      'assets/avatars/avatar_2.png',
      'assets/avatars/avatar_3.png',
      'assets/avatars/avatar_4.png',
      'assets/avatars/avatar_5.png',
    ];
    final selectedAsset = avatarAssets[hash % avatarAssets.length];

    return Image.asset(
      selectedAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: SetlogColors.momentoPinkSurface,
        child: Center(
          child: Text(
            seed.isNotEmpty ? seed[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: SetlogColors.momentoPink,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
