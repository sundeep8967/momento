import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../data/friends_repository.dart';
import '../../theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../avatar_kit/avatar_widget.dart';
import '../../avatar_kit/momento_avatar.dart';

class FriendsScreen extends StatefulWidget {
  final String? initialSearch;
  const FriendsScreen({super.key, this.initialSearch});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  UserProfile? _searchResult;
  bool _isSearching = false;
  String? _searchError;

  List<UserProfile> _friends = [];
  List<Group> _groups = [];
  List<Friendship> _pendingRequests = [];
  Map<String, String> _requesterUsernames = {};
  UserProfile? _myProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
    _loadFriendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await FriendsRepository.instance.getMutualFriends();
      final groups = await FriendsRepository.instance.getMyGroups();
      final pending = await FriendsRepository.instance.getPendingRequests();
      final me = await FriendsRepository.instance.getMyProfile();
      
      final requesterUsernames = <String, String>{};
      for (final req in pending) {
        final profile = await FriendsRepository.instance.getUserProfile(req.requestedBy);
        if (profile != null) {
          requesterUsernames[req.requestedBy] = profile.username;
        }
      }

      if (mounted) {
        setState(() {
          _friends = friends;
          _groups = groups;
          _pendingRequests = pending;
          _requesterUsernames = requesterUsernames;
          _myProfile = me;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() { _isSearching = true; _searchResult = null; _searchError = null; });
    try {
      final result = await FriendsRepository.instance.searchByUsername(q);
      setState(() {
        _searchResult = result;
        _searchError = result == null ? 'No user found for @$q' : null;
        _isSearching = false;
      });
    } catch (_) {
      setState(() { _searchError = 'Search failed. Try again.'; _isSearching = false; });
    }
  }

  Future<void> _sendRequest(String uid) async {
    setState(() => _searchResult = null);
    _searchController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request sent!')),
    );
    try {
      await FriendsRepository.instance.sendFriendRequest(uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(String requesterUid) async {
    await FriendsRepository.instance.acceptRequest(requesterUid);
    await _loadFriendData();
  }

  Future<void> _declineRequest(String requesterUid) async {
    await FriendsRepository.instance.declineOrRemove(requesterUid);
    await _loadFriendData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Squad',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_3_fill, color: SetlogColors.momentoPink, size: 24),
            tooltip: 'Create Group',
            onPressed: () => context.push('/friends/create_group'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: SetlogColors.momentoPink,
          unselectedLabelColor: Colors.black45,
          indicatorColor: SetlogColors.momentoPink,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          dividerColor: Colors.black.withOpacity(0.05),
          tabs: [
            const Tab(text: 'Search'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: SetlogColors.snapViewerAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_pendingRequests.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Groups'),
            const Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildRequestsTab(),
          _buildGroupsTab(),
          _buildFriendsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _search(),
                    style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Search by @username',
                      hintStyle: TextStyle(color: Colors.black38, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(CupertinoIcons.search, color: Colors.black38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _search,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SetlogColors.momentoPink,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: SetlogColors.momentoPink.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_myProfile != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Share.share(
                    'Add me on Momento to see my private video logs! My username is @${_myProfile!.username}.',
                  );
                },
                icon: const Icon(CupertinoIcons.share, color: SetlogColors.momentoPink, size: 18),
                label: const Text('Share Invite Link', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.black.withOpacity(0.08)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          const SizedBox(height: 24),

          if (_searchError != null)
            Text(_searchError!, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500)),

          if (_searchResult != null) _buildUserCard(_searchResult!),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
            ),
            child: AvatarWidget(
              avatar: MomentoAvatar.fromSeed(user.uid),
              size: 44,
              showBorder: false,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black87)),
                    _buildStreakBadge(user),
                  ],
                ),
                Text('@${user.username}',
                    style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _sendRequest(user.uid),
            style: ElevatedButton.styleFrom(
              backgroundColor: SetlogColors.momentoPink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: SetlogColors.momentoPink));
    }
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_add, size: 56, color: Colors.black.withOpacity(0.1))
                .animate().fadeIn(duration: 600.ms).scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text('No pending requests', style: TextStyle(color: Colors.black45, fontSize: 16, fontWeight: FontWeight.w500))
                .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final f = _pendingRequests[i];
        final requesterUid = f.requestedBy;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                ),
                child: AvatarWidget(
                  avatar: MomentoAvatar.fromSeed(requesterUid),
                  size: 44,
                  showBorder: false,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _requesterUsernames[requesterUid] != null ? '@${_requesterUsernames[requesterUid]}' : requesterUid,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
                ),
              ),
              TextButton(
                onPressed: () => _declineRequest(requesterUid),
                child: const Text('Decline', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => _acceptRequest(requesterUid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SetlogColors.momentoPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ).animate(delay: (i * 75).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: SetlogColors.momentoPink));
    }
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_2, size: 64, color: SetlogColors.momentoPink.withOpacity(0.5))
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(end: 1.1, duration: 1500.ms, curve: Curves.easeInOut)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text('No friends yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87))
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text('Search for friends by username',
                style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500))
                .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: SetlogColors.momentoPink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ).animate().fadeIn(delay: 400.ms).scale(),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final f = _friends[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                ),
                child: AvatarWidget(
                  avatar: MomentoAvatar.fromSeed(f.uid),
                  size: 44,
                  showBorder: false,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(f.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black87)),
                        _buildStreakBadge(f),
                      ],
                    ),
                    Text('@${f.username}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.person_badge_minus, color: Colors.black26),
                onPressed: () async {
                  await FriendsRepository.instance.declineOrRemove(f.uid);
                  await _loadFriendData();
                },
              ),
            ],
          ),
        ).animate(delay: (i * 75).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildStreakBadge(UserProfile user) {
    if (user.currentStreak == 0 || user.lastLogDate == null) return const SizedBox.shrink();
    
    final lastDate = DateFormat('yyyy-MM-dd').parse(user.lastLogDate!);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayDate = DateFormat('yyyy-MM-dd').parse(todayStr);
    
    final diff = todayDate.difference(lastDate).inDays;
    if (diff > 1) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
        const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
        const SizedBox(width: 2),
        Text(
          '${user.currentStreak}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: SetlogColors.momentoPink));
    }
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_3, size: 64, color: SetlogColors.snapViewerAccent.withOpacity(0.5))
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(end: 1.1, duration: 1500.ms, curve: Curves.easeInOut)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text('No groups yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87))
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text('Create a group from the top right icon',
                style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500))
                .animate().fadeIn(delay: 300.ms),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final g = _groups[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SetlogColors.momentoPink, SetlogColors.snapViewerAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black87)),
                    Text('${g.members.length} members',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.right_chevron, color: Colors.black26, size: 18),
            ],
          ),
        ).animate(delay: (i * 75).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad);
      },
    );
  }
}


