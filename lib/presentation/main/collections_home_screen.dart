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
                      child: const Icon(CupertinoIcons.person_crop_circle, color: SetlogColors.collectionsHomeTextPrimary, size: 26),
                      onPressed: () => context.push('/main/profile'),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.person_2, color: SetlogColors.collectionsHomeTextPrimary, size: 26),
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
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: SetlogColors.authInk.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  context.push('/main/camera');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Capture',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildSnapRow(List<DirectSnap> userSnaps, int index, String? currentUid) {
    if (userSnaps.isEmpty) return const SizedBox.shrink();
    userSnaps.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final snap = userSnaps.first;
    
    final isNew = userSnaps.any((s) => !s.isViewed);
    final unreadSnaps = userSnaps.where((s) => !s.isViewed).toList();
    
    final isMe = snap.senderUid == currentUid;
    final displayName = isMe ? "${snap.senderUsername} (you)" : snap.senderUsername;
    final unreadCount = unreadSnaps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final snapsList = unreadSnaps.isNotEmpty ? unreadSnaps.reversed.toList() : userSnaps.reversed.toList();
            await context.push('/main/snap_viewer', extra: snapsList);
          },
          child: Container(
            decoration: BoxDecoration(
              color: SetlogColors.collectionsHomeSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNew ? SetlogColors.momentoPinkBorder : SetlogColors.authStrokeSoft.withOpacity(0.5),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Radiant Avatar Ring for unread snaps
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isNew && !isMe
                        ? const LinearGradient(
                            colors: [SetlogColors.momentoPink, SetlogColors.momentoPinkDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: SetlogColors.authSurfaceRaised,
                    child: Text(
                      snap.senderUsername.isNotEmpty ? snap.senderUsername[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: SetlogColors.authInk),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: (isNew && !isMe) ? FontWeight.w700 : FontWeight.w500,
                          color: SetlogColors.collectionsHomeTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            isMe 
                              ? CupertinoIcons.arrow_up_right 
                              : (snap.isVideo ? CupertinoIcons.video_camera_solid : CupertinoIcons.photo_fill),
                            size: 14,
                            color: isNew ? SetlogColors.momentoPink : SetlogColors.collectionsHomeTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isNew 
                                  ? (unreadCount > 1 ? '$unreadCount New Momentos' : 'New Momento')
                                  : (isMe ? (snap.isVideo ? 'You sent a video' : 'You sent a photo') : 'Opened'),
                              style: TextStyle(
                                color: isNew ? SetlogColors.momentoPink : SetlogColors.collectionsHomeTextSecondary,
                                fontSize: 13.5,
                                fontWeight: isNew ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMe) ...[
                  const SizedBox(width: 12),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.camera, color: SetlogColors.collectionsHomeTextSecondary, size: 24),
                    onPressed: () => context.push('/main/camera'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 30).ms).fadeIn(duration: 300.ms);
  }
}
