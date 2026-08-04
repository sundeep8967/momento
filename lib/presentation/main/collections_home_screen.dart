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
import '../../data/friends_repository.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/smoking_mode_provider.dart';
import '../../theme/friend_settings_provider.dart';

class CollectionsHomeScreen extends ConsumerStatefulWidget {
  const CollectionsHomeScreen({super.key});

  @override
  ConsumerState<CollectionsHomeScreen> createState() => _CollectionsHomeScreenState();
}

class _CollectionsHomeScreenState extends ConsumerState<CollectionsHomeScreen> {
  // Track which snap URLs we've already precached so we never schedule a
  // redundant addPostFrameCallback on subsequent stream rebuilds.
  final Set<String> _precachedIds = {};

  // Shared location cache — avoids cold-start GPS blocking on tap.
  // Written by snap_map_screen too; read here for geo-lock distance check.
  static Position? _cachedPosition;


  @override
  Widget build(BuildContext context) {
    final myProfile = ref.watch(myProfileProvider).value;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final inboxAsyncValue = ref.watch(groupedInboxStreamProvider);
    final sendingIds = ref.watch(sendingSnapsProvider);
    final friendships = ref.watch(friendshipsStreamProvider).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      bottomNavigationBar: _buildFloatingBottomBar(context),
      body: inboxAsyncValue.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (originalEntries) {
          // Pre-cache only new unread moment poster images — guard with a Set so
          // we never call addPostFrameCallback more than once per unique snap URL.
          for (final group in originalEntries) {
            for (final s in group) {
              if (!s.isViewed &&
                  s.videoUrl.isNotEmpty &&
                  s.videoUrl.startsWith('http') &&
                  !_precachedIds.contains(s.videoUrl)) {
                _precachedIds.add(s.videoUrl);
                final posterUrl = s.isVideo && s.videoUrl.contains('/upload/')
                    ? s.videoUrl
                        .replaceAll('/upload/', '/upload/f_jpg,q_auto,so_0/')
                        .replaceAll(
                            RegExp(r'\.(mp4|mov|mkv|avi|webm)$',
                                caseSensitive: false),
                            '.jpg')
                    : s.videoUrl;
                // Schedule a single deferred precache — safe, no repeated callbacks
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) { if (mounted) precacheImage(NetworkImage(posterUrl), context); },
                );
              }
            }
          }

          final settings = ref.watch(friendSettingsProvider);
          final pinnedBffUid = settings.pinnedBffUid;

          var entries = List.of(originalEntries);
          if (pinnedBffUid != null) {
            entries.sort((a, b) {
              final aTarget = a.first.groupName ?? a.first.senderUid;
              final bTarget = b.first.groupName ?? b.first.senderUid;
              
              if (aTarget == pinnedBffUid && bTarget != pinnedBffUid) return -1;
              if (bTarget == pinnedBffUid && aTarget != pinnedBffUid) return 1;
              
              return 0; // Maintain original time-based sort for others
            });
          }
          // ── O(1) streak lookup map: built ONCE before the list delegate ──
          // Previously this was an O(N×M) loop inside every list-item builder.
          final Map<String, int> streakByUid = {};
          if (currentUid != null) {
            final now = DateTime.now();
            for (final f in friendships) {
              final lastMe = f.lastSnaps[currentUid];
              if (lastMe == null) continue;
              final otherUid = f.users.firstWhere((u) => u != currentUid, orElse: () => '');
              if (otherUid.isEmpty) continue;
              final lastThem = f.lastSnaps[otherUid];
              if (lastThem == null) continue;
              if (now.difference(lastMe).inHours <= 36 &&
                  now.difference(lastThem).inHours <= 36 &&
                  f.streakCount >= 1) {
                streakByUid[otherUid] = f.streakCount;
              }
            }
          }

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
              // Custom Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                              child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
                            ),
                          ),
                        ),

                        // Title "Momento" (British Handwriting Style - Offline Native)
                        GestureDetector(
                          onTap: () => context.push('/map'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                            ],
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
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Chat Cards List
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_2,
                          size: 56,
                          color: SetlogColors.momentoPink.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Momentos yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add friends and send your first Momento!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final userSnaps = entries[index];
                      userSnaps.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      final snap = userSnaps.first;
                      final isMe = snap.senderUid == currentUid;
                      final partnerUid = snap.senderUid == currentUid 
                          ? (snap.recipientUid ?? currentUid!) 
                          : snap.senderUid;
                      final targetId = snap.groupName ?? partnerUid;
                      final isPinned = targetId == pinnedBffUid;
                      final isSending = sendingIds.contains(targetId);

                      final unreadCount = userSnaps.where((s) => !s.isViewed).length;
                      // isNew = there are unread snaps. For self-snaps (isMe) we still want to open them.
                      final isNew = unreadCount > 0;
                      final displayName = snap.groupName != null && snap.groupName!.isNotEmpty
                          ? snap.groupName!
                          : (targetId == currentUid)
                              ? '${snap.senderUsername} (Myself)'
                              : snap.senderUsername;
                      
                      final displayFinalName = displayName;

                      String displayStatus;
                      Color displayStatusColor;
                      if (isSending) {
                        displayStatus = 'Sending...';
                        displayStatusColor = Colors.blue;
                      } else {
                        if (isNew) {
                          if (snap.lat != null && snap.lng != null) {
                            displayStatus = isMe 
                                ? 'YOUR SECRET MOMENTO • TRAVEL TO UNLOCK' 
                                : 'RECEIVED A SECRET MOMENT • TRAVEL HERE TO UNLOCK';
                          } else {
                            displayStatus = isMe ? 'OPEN MOMENTO • TAP TO VIEW' : 'NEW MOMENTO • TAP TO VIEW';
                          }
                          displayStatusColor = SetlogColors.momentoPink;
                        } else {
                          if (snap.lat != null && snap.lng != null) {
                            displayStatus = isMe ? 'Sent a secret moment' : 'Opened a secret moment';
                          } else {
                            displayStatus = isMe ? 'Delivered' : 'Opened';
                          }
                          displayStatusColor = const Color(0xFF666666);
                        }
                      }

                      // O(1) streak lookup using the pre-built map
                      final finalStreakCount = streakByUid[targetId];

                      return GestureDetector(
                        onLongPress: () {
                          _showFriendOptionsSheet(context, ref, targetId, displayFinalName, isPinned);
                        },
                        onTap: () async {
                          if (isSending) return;
                          if (isNew) {
                            final unreadSnaps = userSnaps.where((s) => !s.isViewed).toList();
                            if (unreadSnaps.isEmpty) return;

                            final firstSnap = unreadSnaps.first;
                            if (firstSnap.lat != null && firstSnap.lng != null) {
                              // ── Fast geo-check: use cached position first (0ms) ──
                              // If no cache, try getLastKnownPosition (fast), then
                              // fall back to getCurrentPosition with a 3-second cap.
                              // We never block the UI indefinitely.
                              double distance = 999999;
                              try {
                                Position? pos = _cachedPosition;
                                if (pos == null) {
                                  pos = await Geolocator.getLastKnownPosition();
                                }
                                if (pos == null) {
                                  final perm = await Geolocator.checkPermission();
                                  if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
                                    pos = await Geolocator.getCurrentPosition(
                                      locationSettings: const LocationSettings(
                                        accuracy: LocationAccuracy.medium,
                                        timeLimit: Duration(seconds: 3),
                                      ),
                                    ).timeout(const Duration(seconds: 3), onTimeout: () async => pos!);
                                  }
                                }
                                if (pos != null) {
                                  _cachedPosition = pos;
                                  distance = Geolocator.distanceBetween(
                                      pos.latitude, pos.longitude,
                                      firstSnap.lat!, firstSnap.lng!);
                                }
                              } catch (_) {}

                              if (distance <= 50) {
                                if (context.mounted) {
                                  context.push('/main/snap_viewer', extra: unreadSnaps);
                                }
                              } else {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text('Secret Momento', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                      content: Text('This is a Secret Momento. You must travel within 50 meters of its location to unlock it!\n\nYou are currently ${distance > 100000 ? "far" : "${distance.toStringAsFixed(0)}m"} away.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            context.push('/map', extra: {
                                              'targetLat': firstSnap.lat,
                                              'targetLng': firstSnap.lng,
                                            });
                                          },
                                          child: const Text('Open Map', style: TextStyle(color: SetlogColors.momentoPink, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            } else {
                              context.push('/main/snap_viewer', extra: unreadSnaps);
                            }
                          }
                        },
                        child: ChatCardItem(
                          name: displayFinalName,
                          status: displayStatus,
                          statusColor: displayStatusColor,
                          time: timeago.format(snap.timestamp, locale: 'en_short').toUpperCase(),
                          streak: finalStreakCount,
                          avatarSeed: targetId,
                          avatarUrl: (targetId == currentUid) ? myProfile?.photoUrl : null,
                          isOpened: !isNew && !isMe,
                          isDelivered: !isNew && isMe,
                          isNew: isNew && !isSending,
                          isVideo: snap.isVideo,
                          isSending: isSending,
                          isPinned: isPinned,
                        ),
                      );
                    },
                    childCount: entries.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ));
        },
      ),
    );
  }

  void _showFriendOptionsSheet(BuildContext context, WidgetRef ref, String targetId, String targetName, bool isPinned) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(targetName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              if (isPinned) {
                ref.read(friendSettingsProvider.notifier).unpinBff();
              } else {
                ref.read(friendSettingsProvider.notifier).setPinnedBff(targetId);
              }
            },
            child: Text(isPinned ? 'Unpin #1 BFF' : 'Pin as #1 BFF 📌', 
              style: TextStyle(color: isPinned ? CupertinoColors.destructiveRed : SetlogColors.momentoPink),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
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
                      child: BouncingButton(
                        onTap: () {}, // Already here
                        child: const Icon(CupertinoIcons.chat_bubble_fill, color: SetlogColors.momentoPink, size: 28),
                      ),
                    ),
                    // Spacer for central camera
                    const SizedBox(width: 80),
                    // Friends Tab (Now Tea or Smoking Icon)
                    Expanded(
                      child: BouncingButton(
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
            child: BouncingButton(
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
  final bool isChatReceived;
  final bool isVideo;
  final bool isSending;
  final bool isPinned;

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
    this.isChatReceived = false,
    this.isVideo = false,
    this.isSending = false,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
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
          // Avatar container with optional Glowing Momento Pink Border for New Moments
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
              child: MomentoProfileAvatar(
                photoUrl: avatarUrl,
                seed: avatarSeed,
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
                    Row(
                      children: [
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Text('📌', style: TextStyle(fontSize: 14)),
                          ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            color: Colors.black,
                          ),
                        ),
                      ],
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
                    Flexible(
                      child: Text(
                        status,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: isNew ? 0.2 : 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· $time',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (isSending) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.blue,
        ),
      );
    } else if (isNew) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: statusColor, // Use the passed status color (e.g., purple/red)
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else if (isOpened) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          border: Border.all(color: statusColor, width: 2),
          borderRadius: BorderRadius.circular(4),
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
      return Icon(CupertinoIcons.play_circle_fill, color: statusColor, size: 14);
    } else {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          border: Border.all(color: statusColor, width: 2),
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

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncingButton({super.key, required this.child, required this.onTap});

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
