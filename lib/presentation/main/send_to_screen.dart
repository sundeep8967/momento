import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:momento/avatar_kit/avatar_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momento/data/friends_repository.dart';
import 'package:momento/data/snap_repository.dart';
import 'package:momento/data/cloudinary_service.dart';
import 'package:momento/data/local_cache.dart';
import 'package:momento/theme/colors.dart';
import 'package:momento/theme/friend_settings_provider.dart';

class SendToScreen extends ConsumerStatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final String? caption;
  final bool isFrontCamera;
  final String? from;

  const SendToScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    this.caption,
    this.isFrontCamera = false,
    this.from,
  });

  @override
  ConsumerState<SendToScreen> createState() => _SendToScreenState();
}

class _SendToScreenState extends ConsumerState<SendToScreen> {
  bool _isLoading = true;
  bool _isSending = false;
  bool _dropOnMap = false;
  bool _postToLocal = false;
  
  List<UserProfile> _friends = [];
  List<Group> _groups = [];
  
  final Set<String> _selectedFriendUids = {};
  final Set<String> _selectedGroupIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.from == 'map') {
      _dropOnMap = true;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    UserProfile? myProfile;

    if (myUid != null) {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      final myUsername = myDoc.exists ? (myDoc.data()?['username'] ?? 'Me') : 'Me';
      myProfile = UserProfile(
        uid: myUid,
        username: myUsername,
        displayName: 'Myself',
        photoUrl: myDoc.data()?['photoUrl'] ?? '',
      );
    }

    // 1. Instant Cache-First Load
    final cachedFriends = await LocalCache.instance.getCachedFriends();
    if (cachedFriends.isNotEmpty && mounted) {
      List<UserProfile> displayCached = List.from(cachedFriends);
      if (myProfile != null) displayCached.insert(0, myProfile);
      
      setState(() {
        _friends = displayCached;
        _isLoading = false;
      });
    }

    try {
      final friends = await FriendsRepository.instance.getMutualFriends();
      final groups = await FriendsRepository.instance.getMyGroups();
      
      List<UserProfile> displayFriends = List.from(friends);
      
      // Fallback: If no accepted mutual friends yet, fetch all registered users so friends are always visible!
      if (displayFriends.isEmpty) {
        final allUsersSnap = await FirebaseFirestore.instance.collection('users').limit(50).get();
        displayFriends = allUsersSnap.docs
            .where((d) => d.id != myUid)
            .map((d) => UserProfile.fromMap(d.id, d.data()))
            .toList();
      }

      // Add "Myself" at the top so you can always send snaps to yourself
      if (myProfile != null) {
        displayFriends.removeWhere((f) => f.uid == myUid); // Ensure no duplicates
        displayFriends.insert(0, myProfile);
      }

      if (mounted) {
        setState(() {
          _friends = displayFriends;
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _friends.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sendSnap() async {
    if (_selectedFriendUids.isEmpty && _selectedGroupIds.isEmpty) return;
    
    // Grab all values we need before we navigate away (so we don't rely on `this.widget` after pop)
    final mediaPath = widget.mediaPath;
    final isVideo = widget.isVideo;
    final isFrontCamera = widget.isFrontCamera;
    final friendUids = _selectedFriendUids.toList();
    final selectedGroups = _groups.where((g) => _selectedGroupIds.contains(g.id)).toList();
    final snapRepo = ref.read(snapRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final sendingNotifier = ref.read(sendingSnapsProvider.notifier);

    final dropOnMap = _dropOnMap;
    final postToLocal = _postToLocal;

    // 0. Fetch location synchronously while the screen is active and context is valid
    double? lat;
    double? lng;
    if (dropOnMap || postToLocal) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    }
    debugPrint('SNAP SEND: dropOnMap=$dropOnMap, lat=$lat, lng=$lng');

    // Add selected users/groups to the sending state
    final sendingIds = {
      ...friendUids,
      ...selectedGroups.map((g) => g.id),
    };
    
    if (sendingIds.isNotEmpty) {
      sendingNotifier.state = {
        ...sendingNotifier.state,
        ...sendingIds,
      };
    }

    // Immediately return to Home Screen or Map Screen
    if (widget.from == 'map') {
      context.go('/map');
    } else {
      context.go('/main');
    }
    
    // Run the heavy lifting in the background
    Future.microtask(() async {
      try {
        // 1. Upload media to Cloudinary
        final mediaUrl = isVideo 
            ? await CloudinaryService.uploadVideo(mediaPath)
            : await CloudinaryService.uploadImage(mediaPath);

        // 2. Send snap via repository
        if (friendUids.isNotEmpty || selectedGroups.isNotEmpty) {
          await snapRepo.sendSnap(
            videoUrl: mediaUrl, 
            isVideo: isVideo,
            friendUids: friendUids,
            groups: selectedGroups,
            lat: dropOnMap ? lat : null,
            lng: dropOnMap ? lng : null,
            isFrontCamera: isFrontCamera,
          );
        }

        if (postToLocal) {
          if (lat != null && lng != null) {
            await snapRepo.sendLocalSnap(
              videoUrl: mediaUrl,
              isVideo: isVideo,
              lat: lat,
              lng: lng,
              isFrontCamera: isFrontCamera,
            );
          }
        }

        // Show success snackbar only for local/map drops if no friends were selected
        if (sendingIds.isEmpty && (postToLocal || dropOnMap)) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Posted to map ✓', style: TextStyle(color: Colors.white)),
              backgroundColor: SetlogColors.authTerminalAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.redAccent),
        );
      } finally {
        // Remove from sending state
        if (sendingIds.isNotEmpty) {
          sendingNotifier.state = {
            ...sendingNotifier.state,
          }..removeWhere((id) => sendingIds.contains(id));
        }
      }
    });
  }

  Widget _buildCircularItem({
    required String emoji,
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isSelected ? SetlogColors.momentoPink.withOpacity(0.15) : SetlogColors.authSurface,
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
                if (isSelected)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: SetlogColors.momentoPink, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 52,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600,
                  color: onTap == null ? Colors.grey : SetlogColors.collectionsHomeTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(friendSettingsProvider);
    final pinnedBffUid = settings.pinnedBffUid;

    final filteredGroups = _searchQuery.isEmpty ? _groups : _groups.where((g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final filteredFriends = _searchQuery.isEmpty ? List<UserProfile>.from(_friends) : _friends.where((f) => 
        f.username.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        f.displayName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    
    if (pinnedBffUid != null) {
      filteredFriends.sort((a, b) {
        if (a.uid == pinnedBffUid && b.uid != pinnedBffUid) return -1;
        if (b.uid == pinnedBffUid && a.uid != pinnedBffUid) return 1;
        return 0; // Maintain existing order
      });
    }
    final showLocal = _searchQuery.isEmpty || 'local map'.contains(_searchQuery.toLowerCase());
    final showDrop = _searchQuery.isEmpty || 'drop on map'.contains(_searchQuery.toLowerCase());
    final hasMapOrGroups = filteredGroups.isNotEmpty || showLocal || showDrop;

    return Scaffold(
      backgroundColor: SetlogColors.collectionsHomeBackground,
      appBar: AppBar(
        backgroundColor: SetlogColors.collectionsHomeBackground,
        title: const Text('Send To', style: TextStyle(color: SetlogColors.collectionsHomeTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: SetlogColors.collectionsHomeTextPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SetlogColors.brownPrimary))
          : _friends.isEmpty && _groups.isEmpty
              ? const Center(child: Text('Add some friends to send moments!', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CupertinoSearchTextField(
                        placeholder: 'Search friends or groups...',
                        style: const TextStyle(color: SetlogColors.collectionsHomeTextPrimary),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    if (hasMapOrGroups)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GROUPS & MAP', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  bool allSelected = filteredGroups.isNotEmpty && _selectedGroupIds.length >= filteredGroups.length;
                                  if (allSelected) {
                                    _selectedGroupIds.removeAll(filteredGroups.map((g) => g.id));
                                  } else {
                                    _selectedGroupIds.addAll(filteredGroups.map((g) => g.id));
                                  }
                                });
                              },
                              child: Text(
                                (filteredGroups.isNotEmpty && filteredGroups.every((g) => _selectedGroupIds.contains(g.id))) ? 'None' : 'All',
                                style: const TextStyle(color: SetlogColors.momentoPink, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasMapOrGroups)
                      SizedBox(
                        height: 80,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (showLocal)
                              _buildCircularItem(
                                emoji: '🌍',
                                label: 'Local',
                                isSelected: _postToLocal,
                                onTap: () => setState(() {
                                  _postToLocal = !_postToLocal;
                                  if (_postToLocal) _dropOnMap = true;
                                }),
                              ),
                            if (showDrop)
                              _buildCircularItem(
                                emoji: '📍',
                                label: 'Drop',
                                isSelected: _dropOnMap,
                                onTap: _postToLocal ? null : () => setState(() => _dropOnMap = !_dropOnMap),
                              ),
                            ...filteredGroups.map((group) {
                              final isSelected = _selectedGroupIds.contains(group.id);
                              return GestureDetector(
                                onLongPress: () {
                                  // Open group chat (not implemented in SendTo)
                                },
                                child: _buildCircularItem(
                                  emoji: '👥',
                                  label: group.name,
                                  isSelected: isSelected,
                                  onTap: () => setState(() {
                                    if (isSelected) {
                                      _selectedGroupIds.remove(group.id);
                                    } else {
                                      _selectedGroupIds.add(group.id);
                                    }
                                  }),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    if (filteredFriends.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('FRIENDS', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  bool allSelected = filteredFriends.isNotEmpty && filteredFriends.every((f) => _selectedFriendUids.contains(f.uid));
                                  if (allSelected) {
                                    _selectedFriendUids.removeAll(filteredFriends.map((f) => f.uid));
                                  } else {
                                    _selectedFriendUids.addAll(filteredFriends.map((f) => f.uid));
                                  }
                                });
                              },
                              child: Text(
                                (filteredFriends.isNotEmpty && filteredFriends.every((f) => _selectedFriendUids.contains(f.uid))) ? 'None' : 'All',
                                style: const TextStyle(color: SetlogColors.momentoPink, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = filteredFriends[index];
                            final isSelected = _selectedFriendUids.contains(friend.uid);
                            final isPinned = friend.uid == pinnedBffUid;
                            final displayName = friend.uid == FirebaseAuth.instance.currentUser?.uid 
                                ? '${friend.username} (Myself)' 
                                : friend.username;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  if (isSelected) _selectedFriendUids.remove(friend.uid);
                                  else _selectedFriendUids.add(friend.uid);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  children: [
                                    // Avatar with Border
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? SetlogColors.momentoPink : const Color(0xFFEEEEEE),
                                          width: 2,
                                        ),
                                      ),
                                      child: MomentoProfileAvatar(
                                        photoUrl: friend.photoUrl,
                                        seed: friend.uid,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Name and Username
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (isPinned)
                                                const Padding(
                                                  padding: EdgeInsets.only(right: 4.0),
                                                  child: Text('📌', style: TextStyle(fontSize: 14)),
                                                ),
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: SetlogColors.collectionsHomeTextPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            friend.displayName.isNotEmpty ? friend.displayName : 'Friend',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF999999),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Checkmark
                                    Icon(
                                      isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                      color: isSelected ? SetlogColors.momentoPink : const Color(0xFFE5E5EA),
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                ),
      floatingActionButton: _selectedFriendUids.isNotEmpty || _selectedGroupIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSending ? null : _sendSnap,
              backgroundColor: SetlogColors.brownPrimary,
              label: _isSending 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send Momento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              icon: _isSending ? null : const Icon(Icons.send, color: Colors.white),
            )
          : null,
    );
  }
}
