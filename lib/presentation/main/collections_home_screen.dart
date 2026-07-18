import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/log_repository.dart';
import '../../data/friends_repository.dart';
import '../../theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:home_widget/home_widget.dart';

class CollectionsHomeScreen extends StatefulWidget {
  const CollectionsHomeScreen({super.key});

  @override
  State<CollectionsHomeScreen> createState() => _CollectionsHomeScreenState();
}

class _CollectionsHomeScreenState extends State<CollectionsHomeScreen> {
  List<SharedLog> _friendsLogs = [];
  List<DayLog> _myLogs = [];
  Map<String, UserProfile> _friendProfiles = {};
  UserProfile? _myProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    // Close any expired logs first
    try {
      final mutualUids = await FriendsRepository.instance.getMutualFriendUids();
      await LogRepository.instance.checkAndCloseExpiredLogs(mutualUids);
    } catch (_) {}

    try {
      final friendsLogs = await LogRepository.instance.getFriendsSharedLogs();
      final myLogs = await LogRepository.instance.getMyDayLogs();
      final mutuals = await FriendsRepository.instance.getMutualFriends();
      final me = await FriendsRepository.instance.getMyProfile();
      if (mounted) {
        setState(() {
          _friendsLogs = friendsLogs;
          _myLogs = myLogs;
          _friendProfiles = { for (var f in mutuals) f.uid : f };
          _myProfile = me;
          _isLoading = false;
        });
      }
      
      // Update Home Screen Widget
      if (friendsLogs.isNotEmpty) {
        // Sort to find the most recent (or first unviewed)
        final sortedLogs = List<SharedLog>.from(friendsLogs)
          ..sort((a, b) {
            if (!a.isViewedByMe && b.isViewedByMe) return -1;
            if (a.isViewedByMe && !b.isViewedByMe) return 1;
            return b.date.compareTo(a.date);
          });
          
        final latest = sortedLogs.first;
        if (latest.clips.isNotEmpty) {
          final cloudUrl = latest.clips.first.cloudUrl;
          final lastDotIndex = cloudUrl.lastIndexOf('.');
          final imageUrl = lastDotIndex != -1 
              ? '${cloudUrl.substring(0, lastDotIndex)}.jpg' 
              : cloudUrl;
              
          // App Group is required for iOS widgets to share data
          await HomeWidget.setAppGroupId('group.com.setlog.momento');
          await HomeWidget.saveWidgetData<String>('latest_log_username', latest.ownerUsername);
          await HomeWidget.saveWidgetData<String>('latest_log_image_url', imageUrl);
          await HomeWidget.updateWidget(name: 'MomentoWidget', iOSName: 'MomentoWidget');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.collectionsHomeBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Text(
                    'Momento',
                    style: TextStyle(
                      color: SetlogColors.collectionsHomeTextPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.person_outline,
                        color: SetlogColors.collectionsHomeTextPrimary, size: 26),
                    onPressed: () => context.push('/main/profile'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.group_outlined,
                        color: SetlogColors.collectionsHomeTextPrimary, size: 26),
                    onPressed: () => context.push('/friends'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: CustomScrollView(
                        slivers: [
                          // ── Friends Story Circles ──
                          SliverToBoxAdapter(
                            child: _buildFriendStoryBar(),
                          ),

                          // ── My Logs Section Header ──
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                              child: Text(
                                'Your Logs',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: SetlogColors.collectionsHomeTextPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),

                          // ── My Logs Grid ──
                          _myLogs.isEmpty && _friendProfiles.isEmpty
                              ? SliverFillRemaining(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.auto_awesome,
                                              size: 64,
                                              color: SetlogColors.authTerminalAccent)
                                              .animate(onPlay: (c) => c.repeat(reverse: true))
                                              .scaleXY(end: 1.1, duration: 1500.ms, curve: Curves.easeInOut)
                                              .animate().fadeIn(duration: 800.ms),
                                          const SizedBox(height: 24),
                                          const Text(
                                            'Welcome to Momento!',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: SetlogColors.collectionsHomeTextPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Momento is a private space for you and your closest friends. Start by inviting your squad or recording your first private log.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: SetlogColors.collectionsHomeTextSecondary,
                                              height: 1.4,
                                            ),
                                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                                          const SizedBox(height: 40),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                if (_myProfile != null) {
                                                  Share.share(
                                                    'Add me on Momento to see my private video logs! My username is @${_myProfile!.username}. Download the app here: https://momento.app/add/${_myProfile!.username}',
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.group_add, color: Colors.white),
                                              label: const Text('Invite Friends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ),
                                          ).animate().fadeIn(delay: 400.ms).scale(),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                await context.push('/main/camera');
                                                _load();
                                              },
                                              icon: const Icon(Icons.videocam, color: SetlogColors.authTerminalAccent),
                                              label: const Text('Take First Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SetlogColors.authInk)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: SetlogColors.authStrokeSoft),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                            ),
                                          ).animate().fadeIn(delay: 500.ms).scale(),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : _myLogs.isEmpty
                                  ? SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.videocam_outlined,
                                                size: 52,
                                                color: SetlogColors.collectionsHomeTextSecondary),
                                            const SizedBox(height: 14),
                                            const Text(
                                              'No logs yet',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: SetlogColors.collectionsHomeTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Tap the camera button\nto record your first moment',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: SetlogColors.collectionsHomeTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SliverPadding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.85,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final log = _myLogs[index];
                                        return _buildMyLogCard(log, index);
                                      },
                                      childCount: _myLogs.length,
                                    ),
                                  ),
                                ),

                          const SliverToBoxAdapter(child: SizedBox(height: 100)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/main/camera');
          _load();
        },
        backgroundColor: SetlogColors.authInk,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.videocam, size: 28),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildFriendStoryBar() {
    // Determine if we have our own log to show
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final myActiveLog = _myLogs.where((log) => log.date == todayStr && log.clipCount > 0).firstOrNull;
    
    if (_friendsLogs.isEmpty && myActiveLog == null) {
      return const SizedBox(height: 8);
    }

    // Sort: unviewed first
    final sorted = List<SharedLog>.from(_friendsLogs)
      ..sort((a, b) {
        if (!a.isViewedByMe && b.isViewedByMe) return -1;
        if (a.isViewedByMe && !b.isViewedByMe) return 1;
        return 0;
      });

    final itemCount = sorted.length + (myActiveLog != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Text(
            'Squad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SetlogColors.collectionsHomeTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemCount,
            itemBuilder: (context, i) {
              final isMyLog = myActiveLog != null && i == 0;
              final index = isMyLog ? 0 : (myActiveLog != null ? i - 1 : i);
              
              if (isMyLog) {
                return _buildStoryCircle(
                  isMine: true,
                  uid: _myProfile?.uid ?? '',
                  username: 'My Story',
                  photoUrl: _myProfile?.photoUrl,
                  isViewed: true, // We assume the user has seen their own story while recording it
                  logId: myActiveLog.id,
                  animationIndex: i,
                );
              }
              
              final log = sorted[index];
              return _buildStoryCircle(
                isMine: false,
                uid: log.ownerUid,
                username: log.ownerUsername,
                photoUrl: _friendProfiles[log.ownerUid]?.photoUrl,
                isViewed: log.isViewedByMe,
                logId: log.id,
                animationIndex: i,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStoryCircle({
    required bool isMine,
    required String uid,
    required String username,
    String? photoUrl,
    required bool isViewed,
    required String logId,
    required int animationIndex,
  }) {
    return GestureDetector(
      onTap: () async {
        if (isMine) {
          await context.push('/main/daylog/$logId');
        } else {
          await context.push('/friends/log/$logId');
        }
        _load(); // Refresh view state
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isViewed
                        ? null
                        : const LinearGradient(
                            colors: [
                              SetlogColors.accountGreen,
                              SetlogColors.accountBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: isViewed
                        ? Border.all(
                            color: SetlogColors.authStrokeSoft,
                            width: 2.5,
                          )
                        : null,
                    color: isViewed
                        ? SetlogColors.collectionsHomeSurface
                        : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isViewed ? 0.0 : 3.0),
                    child: CircleAvatar(
                      backgroundColor: isViewed
                          ? SetlogColors.collectionsHomeSurface
                          : SetlogColors.authSurface,
                      radius: 26,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                      child: (photoUrl != null && photoUrl.isNotEmpty) ? null : Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: isViewed
                              ? SetlogColors.collectionsHomeTextSecondary
                              : SetlogColors.authInk,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isMine) Builder(
                  builder: (context) {
                    final profile = _friendProfiles[uid];
                    if (profile == null || profile.currentStreak == 0 || profile.lastLogDate == null) return const SizedBox.shrink();
                    
                    final lastDate = DateFormat('yyyy-MM-dd').parse(profile.lastLogDate!);
                    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final todayDate = DateFormat('yyyy-MM-dd').parse(todayStr);
                    
                    final diff = todayDate.difference(lastDate).inDays;
                    if (diff > 1) return const SizedBox.shrink();
                    
                    return Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: SetlogColors.authInk,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SetlogColors.collectionsHomeBackground, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, color: SetlogColors.authTerminalAccent, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '${profile.currentStreak}',
                              style: const TextStyle(
                                color: SetlogColors.authTerminalAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 60,
              child: Text(
                username,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isViewed
                      ? SetlogColors.collectionsHomeTextSecondary
                      : SetlogColors.collectionsHomeTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (animationIndex * 75).ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildMyLogCard(DayLog log, int index) {
    final dt = DateFormat('yyyy-MM-dd').tryParse(log.date);
    final displayDate = dt != null ? DateFormat('MMM d').format(dt) : log.date;
    final isToday = log.date == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return GestureDetector(
      onTap: () async {
        if (log.clipCount > 0) {
          await context.push('/main/daylog/${log.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: SetlogColors.collectionsHomeSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isToday
                ? SetlogColors.authTerminalAccent
                : SetlogColors.authStrokeSoft,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(17)),
                  color: log.isClosed
                      ? SetlogColors.authInk.withOpacity(0.07)
                      : SetlogColors.authTerminalAccent.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    log.clipCount > 0
                        ? Icons.play_circle_fill
                        : Icons.videocam_outlined,
                    size: 40,
                    color: log.clipCount > 0
                        ? SetlogColors.authInk
                        : SetlogColors.collectionsHomeTextSecondary,
                  ),
                ),
              ),
            ),

            // Metadata
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: SetlogColors.collectionsHomeTextPrimary,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SetlogColors.authTerminalAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: SetlogColors.authInk),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${log.clipCount} clip${log.clipCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: SetlogColors.collectionsHomeTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 75).ms).fadeIn(duration: 400.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack);
  }
}
