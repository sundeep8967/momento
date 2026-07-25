import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:momento/avatar_kit/avatar_widget.dart';
import 'package:momento/avatar_kit/momento_avatar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momento/data/friends_repository.dart';
import 'package:momento/data/snap_repository.dart';
import 'package:momento/data/cloudinary_service.dart';
import 'package:momento/data/local_cache.dart';
import 'package:momento/theme/colors.dart';
import '../../avatar_kit/avatar_widget.dart';

class SendToScreen extends ConsumerStatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final String? caption;

  const SendToScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    this.caption,
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
    final friendUids = _selectedFriendUids.toList();
    final selectedGroups = _groups.where((g) => _selectedGroupIds.contains(g.id)).toList();
    final snapRepo = ref.read(snapRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Immediately return to Home Screen for that snappy iOS feel!
    context.go('/main');
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Sending Momento...'), backgroundColor: SetlogColors.collectionsHomeBackground, duration: Duration(seconds: 2))
    );
    
    // Run the heavy lifting in the background
    Future.microtask(() async {
      try {
        // 0. Fetch location if dropping on map
        double? lat;
        double? lng;
        if (_dropOnMap) {
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
            lat: lat,
            lng: lng,
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
            lat: lat!,
            lng: lng!,
          );
        }

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Momento sent!'), backgroundColor: SetlogColors.authTerminalAccent)
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.redAccent)
        );
      }
    });
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
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SetlogColors.authStrokeSoft),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('🌍 Post to Local Map', style: TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.collectionsHomeTextPrimary)),
                            subtitle: const Text('Make this public for anyone nearby to find!', style: TextStyle(fontSize: 12, color: SetlogColors.collectionsHomeTextSecondary)),
                            activeColor: SetlogColors.momentoPink,
                            value: _postToLocal,
                            onChanged: (val) {
                              setState(() {
                                _postToLocal = val;
                                if (val) _dropOnMap = true; // Local snaps must be dropped on map
                              });
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('📍 Drop on Map', style: TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.collectionsHomeTextPrimary)),
                            subtitle: const Text('Friends must physically walk here to unlock it!', style: TextStyle(fontSize: 12, color: SetlogColors.collectionsHomeTextSecondary)),
                            activeColor: SetlogColors.momentoPink,
                            value: _dropOnMap,
                            onChanged: _postToLocal ? null : (val) {
                              setState(() {
                                _dropOnMap = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_groups.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text('GROUPS', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(
                        height: 96,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            final group = _groups[index];
                            final isSelected = _selectedGroupIds.contains(group.id);
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) _selectedGroupIds.remove(group.id);
                                  else _selectedGroupIds.add(group.id);
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: isSelected ? SetlogColors.momentoPink.withOpacity(0.15) : SetlogColors.authSurface,
                                          backgroundImage: group.photoUrl != null ? NetworkImage(group.photoUrl!) : null,
                                          child: group.photoUrl == null 
                                              ? Icon(
                                                  CupertinoIcons.group_solid, 
                                                  color: isSelected ? SetlogColors.momentoPink : SetlogColors.brownPrimary,
                                                  size: 28,
                                                )
                                              : null,
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(CupertinoIcons.checkmark_circle_fill, color: SetlogColors.momentoPink, size: 22),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 68,
                                      child: Text(
                                        group.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected ? SetlogColors.momentoPink : SetlogColors.collectionsHomeTextPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_friends.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text('FRIENDS', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        color: SetlogColors.authSurface,
                        child: Column(
                          children: _friends.map((friend) {
                            final isSelected = _selectedFriendUids.contains(friend.uid);
                                return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  leading: friend.avatar != null
                                      ? AvatarWidget(avatar: friend.avatar!, size: 40)
                                      : CircleAvatar(
                                          backgroundColor: SetlogColors.brownPrimary.withOpacity(0.1),
                                          child: Text(
                                            friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.brownPrimary),
                                          ),
                                        ),
                                  title: Text(
                                    friend.uid == FirebaseAuth.instance.currentUser?.uid 
                                        ? '${friend.username} (Myself)' 
                                        : friend.username, 
                                    style: const TextStyle(fontWeight: FontWeight.w500, color: SetlogColors.collectionsHomeTextPrimary)
                                  ),
                                  trailing: Icon(
                                    isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                    color: isSelected ? SetlogColors.brownPrimary : CupertinoColors.systemGrey4,
                                    size: 28,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) _selectedFriendUids.remove(friend.uid);
                                      else _selectedFriendUids.add(friend.uid);
                                    });
                                  },
                                ),
                                if (friend != _friends.last)
                                  const Divider(height: 1, indent: 76, color: SetlogColors.authStrokeSoft),
                              ],
                            );
                          }).toList(),
                        ),
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
