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

class SendToScreen extends ConsumerStatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final String? caption;
  final bool isFrontCamera;

  const SendToScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    this.caption,
    this.isFrontCamera = false,
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

  @override
  void initState() {
    super.initState();
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

  void _sendSnap() {
    if (_selectedFriendUids.isEmpty && _selectedGroupIds.isEmpty) return;
    
    // Grab all values we need before we navigate away (so we don't rely on `this.widget` after pop)
    final mediaPath = widget.mediaPath;
    final isVideo = widget.isVideo;
    final isFrontCamera = widget.isFrontCamera;
    final friendUids = _selectedFriendUids.toList();
    final selectedGroups = _groups.where((g) => _selectedGroupIds.contains(g.id)).toList();
    final snapRepo = ref.read(snapRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Immediately return to Home Screen
    context.go('/main');

    // Show persistent "Sending..." snackbar — it stays until we explicitly dismiss it
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Sending...', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: SetlogColors.brownPrimary,
        duration: Duration(days: 1), // effectively permanent until dismissed
      ),
    );
    
    // Run the heavy lifting in the background
    Future.microtask(() async {
      try {
        // 0. Fetch location if dropping on map
        double? lat;
        double? lng;
        if (_dropOnMap || _postToLocal) {
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
        }

        // 1. Upload media to Cloudinary
        final mediaUrl = isVideo 
            ? await CloudinaryService.uploadVideo(mediaPath)
            : await CloudinaryService.uploadImage(mediaPath);

        // 2. Send snap via repository
        if (_selectedFriendUids.isNotEmpty || selectedGroups.isNotEmpty) {
          await snapRepo.sendSnap(
            videoUrl: mediaUrl, 
            isVideo: isVideo,
            friendUids: friendUids,
            groups: selectedGroups,
            lat: _dropOnMap ? lat : null,
            lng: _dropOnMap ? lng : null,
            isFrontCamera: isFrontCamera,
          );
        }

        if (_postToLocal) {
          // Send to public local map
          if (lat == null || lng == null) {
            Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            lat = position.latitude;
            lng = position.longitude;
          }
          await snapRepo.sendLocalSnap(
            videoUrl: mediaUrl,
            isVideo: isVideo,
            lat: lat,
            lng: lng,
            isFrontCamera: isFrontCamera,
          );
        }

        // Dismiss "Sending..." and show "Delivered ✓"
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Delivered ✓', style: TextStyle(color: Colors.white)),
            backgroundColor: SetlogColors.authTerminalAccent,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.redAccent),
        );
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
    return Scaffold(
      backgroundColor: SetlogColors.collectionsHomeBackground,
      appBar: AppBar(
        backgroundColor: SetlogColors.collectionsHomeBackground,
        title: const Text('Send To', style: TextStyle(color: SetlogColors.collectionsHomeTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: SetlogColors.collectionsHomeTextPrimary),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                final allSelected = _selectedFriendUids.length == _friends.length && 
                                    (_groups.isEmpty || _selectedGroupIds.length == _groups.length);
                if (allSelected) {
                  // Deselect all
                  _selectedFriendUids.clear();
                  _selectedGroupIds.clear();
                } else {
                  // Select all
                  _selectedFriendUids.addAll(_friends.map((f) => f.uid));
                  _selectedGroupIds.addAll(_groups.map((g) => g.id));
                }
              });
            },
            child: Text(
              _selectedFriendUids.length == _friends.length && (_groups.isEmpty || _selectedGroupIds.length == _groups.length) && _friends.isNotEmpty 
                  ? 'Deselect All' 
                  : 'Select All',
              style: const TextStyle(color: SetlogColors.momentoPink, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SetlogColors.brownPrimary))
          : _friends.isEmpty && _groups.isEmpty
              ? const Center(child: Text('Add some friends to send snaps!', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GROUPS & MAP', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                bool allSelected = _groups.isNotEmpty && _selectedGroupIds.length == _groups.length;
                                if (allSelected) {
                                  _selectedGroupIds.clear();
                                } else {
                                  _selectedGroupIds.addAll(_groups.map((g) => g.id));
                                }
                              });
                            },
                            child: Text(
                              (_groups.isNotEmpty && _selectedGroupIds.length == _groups.length) ? 'None' : 'All',
                              style: const TextStyle(color: SetlogColors.momentoPink, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: _groups.length + 2,
                        itemBuilder: (context, index) {
                          // 0: Local Map
                          if (index == 0) {
                            return _buildCircularItem(
                              emoji: '🌍',
                              label: 'Local',
                              isSelected: _postToLocal,
                              onTap: () => setState(() {
                                _postToLocal = !_postToLocal;
                                if (_postToLocal) _dropOnMap = true;
                              }),
                            );
                          }
                          // 1: Drop on Map
                          if (index == 1) {
                            return _buildCircularItem(
                              emoji: '📍',
                              label: 'Drop',
                              isSelected: _dropOnMap,
                              onTap: _postToLocal ? null : () => setState(() => _dropOnMap = !_dropOnMap),
                            );
                          }

                          // 2+: Real Groups
                          final group = _groups[index - 2];
                          final isSelected = _selectedGroupIds.contains(group.id);
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) _selectedGroupIds.remove(group.id);
                                else _selectedGroupIds.add(group.id);
                              });
                            },
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
                                        backgroundImage: group.photoUrl != null ? NetworkImage(group.photoUrl!) : null,
                                        child: group.photoUrl == null 
                                            ? Icon(
                                                CupertinoIcons.group_solid, 
                                                color: isSelected ? SetlogColors.momentoPink : SetlogColors.brownPrimary,
                                                size: 24,
                                              )
                                            : null,
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
                                      group.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_friends.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('FRIENDS', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedFriendUids.length == _friends.length) {
                                    _selectedFriendUids.clear();
                                  } else {
                                    _selectedFriendUids.addAll(_friends.map((f) => f.uid));
                                  }
                                });
                              },
                              child: Text(
                                _selectedFriendUids.length == _friends.length ? 'None' : 'All',
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
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            final isSelected = _selectedFriendUids.contains(friend.uid);
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
                                      child: friend.avatar != null
                                          ? AvatarWidget(avatar: friend.avatar!, size: 48)
                                          : CircleAvatar(
                                              radius: 24,
                                              backgroundColor: SetlogColors.brownPrimary.withOpacity(0.1),
                                              child: Text(
                                                friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.brownPrimary, fontSize: 20),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Name and Username
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                              letterSpacing: -0.2,
                                            ),
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
