import 'package:flutter/material.dart';
import '../../data/friends_repository.dart';
import '../../theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

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
  List<Friendship> _pendingRequests = [];
  UserProfile? _myProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final pending = await FriendsRepository.instance.getPendingRequests();
      final me = await FriendsRepository.instance.getMyProfile();
      if (mounted) {
        setState(() {
          _friends = friends;
          _pendingRequests = pending;
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
    await FriendsRepository.instance.sendFriendRequest(uid);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request sent!')),
    );
    setState(() => _searchResult = null);
    _searchController.clear();
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
      backgroundColor: SetlogColors.authCanvas,
      appBar: AppBar(
        backgroundColor: SetlogColors.authCanvas,
        elevation: 0,
        title: const Text(
          'Squad',
          style: TextStyle(
            color: SetlogColors.authInk,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: SetlogColors.authInk),
        bottom: TabBar(
          controller: _tabController,
          labelColor: SetlogColors.authInk,
          unselectedLabelColor: SetlogColors.authMuted,
          indicatorColor: SetlogColors.authInk,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: SetlogColors.authTerminalAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_pendingRequests.length}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: SetlogColors.authInk),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildRequestsTab(),
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
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(color: SetlogColors.authInk, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search by @username',
                    hintStyle: const TextStyle(color: SetlogColors.authMuted),
                    prefixIcon: const Icon(Icons.search, color: SetlogColors.authMuted),
                    filled: true,
                    fillColor: SetlogColors.authSurfaceRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _search,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SetlogColors.authInk,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
                    'Add me on Momento to see my private video logs! My username is @${_myProfile!.username}. Download the app here: https://momento.app/add/${_myProfile!.username}',
                  );
                },
                icon: const Icon(Icons.share, color: SetlogColors.authTerminalAccent),
                label: const Text('Share Invite Link', style: TextStyle(color: SetlogColors.authInk)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: SetlogColors.authStrokeSoft),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          const SizedBox(height: 24),

          if (_searchError != null)
            Text(_searchError!,
                style: const TextStyle(color: SetlogColors.authMuted, fontSize: 14)),

          if (_searchResult != null) _buildUserCard(_searchResult!),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SetlogColors.authSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SetlogColors.authStrokeSoft),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: SetlogColors.authTerminalAccent,
            radius: 22,
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: SetlogColors.authInk,
                  fontSize: 18),
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
                            color: SetlogColors.authInk)),
                    _buildStreakBadge(user),
                  ],
                ),
                Text('@${user.username}',
                    style: const TextStyle(fontSize: 13, color: SetlogColors.authMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _sendRequest(user.uid),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingRequests.isEmpty) {
      return Center(
        child: const Text('No pending requests', style: TextStyle(color: SetlogColors.authMuted))
            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
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
            color: SetlogColors.authSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SetlogColors.authStrokeSoft),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: SetlogColors.authButter,
                radius: 22,
                child: Icon(Icons.person, color: SetlogColors.authInk, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  requesterUid,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: SetlogColors.authInk),
                ),
              ),
              TextButton(
                onPressed: () => _declineRequest(requesterUid),
                child: const Text('Decline',
                    style: TextStyle(color: SetlogColors.authMuted)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => _acceptRequest(requesterUid),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ).animate(delay: (i * 75).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 56, color: SetlogColors.authStrokeSoft)
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
                    color: SetlogColors.authInk))
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text('Search for friends by username',
                style: TextStyle(color: SetlogColors.authMuted))
                .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Search'),
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
            color: SetlogColors.authSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SetlogColors.authStrokeSoft),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: SetlogColors.accountGreen,
                radius: 22,
                child: Text(
                  f.displayName.isNotEmpty ? f.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: SetlogColors.authInk,
                      fontSize: 18),
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
                                fontSize: 15,
                                color: SetlogColors.authInk)),
                        _buildStreakBadge(f),
                      ],
                    ),
                    Text('@${f.username}',
                        style: const TextStyle(
                            fontSize: 13, color: SetlogColors.authMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    color: SetlogColors.authMuted),
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
        const Icon(Icons.local_fire_department, color: SetlogColors.authTerminalAccent, size: 16),
        const SizedBox(width: 2),
        Text(
          '${user.currentStreak}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: SetlogColors.authTerminalAccent,
          ),
        ),
      ],
    );
  }
}
