import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:momento/data/snap_repository.dart';
import 'package:momento/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:momento/data/friends_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollectionsHomeScreen extends ConsumerStatefulWidget {
  const CollectionsHomeScreen({super.key});

  @override
  ConsumerState<CollectionsHomeScreen> createState() => _CollectionsHomeScreenState();
}

class _CollectionsHomeScreenState extends ConsumerState<CollectionsHomeScreen> {
  UserProfile? _myProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await FriendsRepository.instance.getMyProfile();
    if (mounted) {
      setState(() => _myProfile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapRepo = ref.read(snapRepositoryProvider);

    return Scaffold(
      backgroundColor: SetlogColors.collectionsHomeBackground,
      body: StreamBuilder<List<DirectSnap>>(
        stream: snapRepo.getInboxStream(),
        builder: (context, snapshot) {
          final allSnaps = snapshot.data ?? [];
          final Map<String, List<DirectSnap>> grouped = {};
          for (final snap in allSnaps) {
            grouped.putIfAbsent(snap.senderUid, () => []).add(snap);
          }
          final groupedSnapsList = grouped.values.toList();
          final currentUid = FirebaseAuth.instance.currentUser?.uid;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── iOS Style Dynamic Navigation Bar ──
              CupertinoSliverNavigationBar(
                backgroundColor: SetlogColors.collectionsHomeBackground.withOpacity(0.85),
                border: null,
                alwaysShowMiddle: false,
                middle: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset('assets/app_icon.png', width: 24, height: 24),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Momento',
                      style: TextStyle(
                        color: SetlogColors.collectionsHomeTextPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                largeTitle: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/app_icon.png', width: 32, height: 32),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Momento',
                      style: TextStyle(
                        color: SetlogColors.collectionsHomeTextPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(Icons.person_outline, color: SetlogColors.collectionsHomeTextPrimary, size: 26),
                      onPressed: () => context.push('/main/profile'),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(Icons.group_outlined, color: SetlogColors.collectionsHomeTextPrimary, size: 26),
                      onPressed: () => context.push('/friends'),
                    ),
                  ],
                ),
              ),

              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groupedSnapsList.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No snaps yet.\nSend one to a friend!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 16),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final userSnaps = groupedSnapsList[index];
                      return _buildSnapRow(userSnaps, index, currentUid);
                    },
                    childCount: groupedSnapsList.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/main/camera');
        },
        backgroundColor: SetlogColors.authInk,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.videocam, size: 28),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildSnapRow(List<DirectSnap> userSnaps, int index, String? currentUid) {
    if (userSnaps.isEmpty) return const SizedBox.shrink();
    userSnaps.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final snap = userSnaps.first;
    
    final isNew = userSnaps.any((s) => !s.isViewed);
    final unreadSnaps = userSnaps.where((s) => !s.isViewed).toList();
    final snapsToPlay = unreadSnaps.isNotEmpty ? unreadSnaps.reversed.toList() : userSnaps; // Play oldest unread first
    
    final isMe = snap.senderUid == currentUid;
    final displayName = isMe ? "${snap.senderUsername} (you)" : snap.senderUsername;
    final unreadCount = unreadSnaps.length;

    return InkWell(
      onTap: () async {
        // Always play snaps. Play unread ones if available, otherwise replay all.
        final snapsList = unreadSnaps.isNotEmpty ? unreadSnaps.reversed.toList() : userSnaps.reversed.toList();
        await context.push('/main/snap_viewer', extra: snapsList);
      },
      child: Container(
        color: SetlogColors.collectionsHomeBackground,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Minimalist Avatar with floating unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: SetlogColors.authSurface,
                  child: Text(
                    snap.senderUsername.isNotEmpty ? snap.senderUsername[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: SetlogColors.authInk),
                  ),
                ),
                // Removed redundant floating dot
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: (isNew && !isMe) ? FontWeight.w600 : FontWeight.w400,
                      color: SetlogColors.collectionsHomeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isNew)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: CupertinoColors.activeBlue,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        Icon(
                          isMe 
                            ? CupertinoIcons.arrow_up_right 
                            : (snap.isVideo ? CupertinoIcons.video_camera : CupertinoIcons.photo),
                          size: 14,
                          color: SetlogColors.collectionsHomeTextSecondary,
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isNew 
                              ? (unreadCount > 1 ? '$unreadCount New Momentos' : 'New Momento')
                              : (isMe ? (snap.isVideo ? 'You sent a video' : 'You sent a photo') : 'Opened'),
                          style: TextStyle(
                            color: isNew ? CupertinoColors.activeBlue : SetlogColors.collectionsHomeTextSecondary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (snap.groupName != null) ...[
                        const SizedBox(width: 4),
                        const Text('·', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary)),
                        const SizedBox(width: 4),
                        Text(
                          snap.groupName!,
                          style: const TextStyle(fontSize: 14, color: SetlogColors.collectionsHomeTextSecondary),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeago.format(snap.timestamp, locale: 'en_short'),
              style: TextStyle(
                color: (isNew && !isMe) ? CupertinoColors.activeBlue : SetlogColors.collectionsHomeTextSecondary, 
                fontSize: 14,
              ),
            ),
            if (!isMe) ...[
              const SizedBox(width: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                child: const Icon(CupertinoIcons.camera, color: SetlogColors.collectionsHomeTextSecondary, size: 24),
                onPressed: () => context.push('/main/camera'),
              ),
            ]
          ],
        ),
      ),
    ).animate(delay: (index * 30).ms).fadeIn(duration: 300.ms);
  }
}
