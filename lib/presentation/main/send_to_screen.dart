import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momento/data/friends_repository.dart';
import 'package:momento/data/snap_repository.dart';
import 'package:momento/data/cloudinary_service.dart';
import 'package:momento/data/local_cache.dart';
import 'package:momento/theme/colors.dart';
import 'dart:io';

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
    // 1. Instant Cache-First Load
    final cachedFriends = await LocalCache.instance.getCachedFriends();
    if (cachedFriends.isNotEmpty && mounted) {
      setState(() {
        _friends = cachedFriends;
        _isLoading = false;
      });
    }

    try {
      final friends = await FriendsRepository.instance.getMutualFriends();
      final groups = await FriendsRepository.instance.getMyGroups();
      if (mounted) {
        setState(() {
          _friends = friends;
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _friends.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
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
        // 1. Upload media to Cloudinary
        final mediaUrl = isVideo 
            ? await CloudinaryService.uploadVideo(mediaPath)
            : await CloudinaryService.uploadImage(mediaPath);

        // 2. Send snap via repository
        await snapRepo.sendSnap(
          videoUrl: mediaUrl, 
          isVideo: isVideo,
          friendUids: friendUids,
          groups: selectedGroups,
        );

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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SetlogColors.brownPrimary))
          : _friends.isEmpty && _groups.isEmpty
              ? const Center(child: Text('Add some friends to send snaps!', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    if (_groups.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text('GROUPS', style: TextStyle(color: SetlogColors.collectionsHomeTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        color: SetlogColors.authSurface,
                        child: Column(
                          children: _groups.map((group) {
                            final isSelected = _selectedGroupIds.contains(group.id);
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: SetlogColors.brownPrimary.withOpacity(0.1),
                                    child: Icon(CupertinoIcons.group_solid, color: SetlogColors.brownPrimary),
                                  ),
                                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w500, color: SetlogColors.collectionsHomeTextPrimary)),
                                  trailing: Icon(
                                    isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                    color: isSelected ? SetlogColors.brownPrimary : CupertinoColors.systemGrey4,
                                    size: 28,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) _selectedGroupIds.remove(group.id);
                                      else _selectedGroupIds.add(group.id);
                                    });
                                  },
                                ),
                                if (group != _groups.last)
                                  const Divider(height: 1, indent: 76, color: SetlogColors.authStrokeSoft),
                              ],
                            );
                          }).toList(),
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
                                  leading: CircleAvatar(
                                    backgroundColor: SetlogColors.brownPrimary.withOpacity(0.1),
                                    child: Text(
                                      friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.brownPrimary),
                                    ),
                                  ),
                                  title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.w500, color: SetlogColors.collectionsHomeTextPrimary)),
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
