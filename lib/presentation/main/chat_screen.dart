import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';
import '../../data/friends_repository.dart';
import '../../avatar_kit/avatar_widget.dart';
import '../../avatar_kit/momento_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String uid;
  
  const ChatScreen({super.key, required this.uid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    if (widget.uid.startsWith('mock_user_')) {
      setState(() {
        _userProfile = UserProfile(
          uid: widget.uid,
          username: 'mock_tester_${widget.uid.split('_').last}',
          displayName: 'Tester',
          photoUrl: '',
          createdAt: DateTime.now(),
          currentStreak: 0,
          longestStreak: 0,
          lastLogDate: null,
        );
      });
    } else {
      final profile = await FriendsRepository.instance.getUserProfile(widget.uid);
      if (mounted) setState(() => _userProfile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            AvatarWidget(
              avatar: _userProfile?.avatar ?? MomentoAvatar.fromSeed(widget.uid),
              size: 36,
              showBorder: false,
            ),
            const SizedBox(width: 12),
            Text(
              _userProfile?.displayName ?? 'Loading...',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Messages (Empty for now)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              reverse: true, // Start from bottom
              children: const [
                // In the future, chat bubbles go here
              ],
            ),
          ),
          
          // Chat Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.camera_fill, color: Colors.grey, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Send a chat...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (text) async {
                        if (text.trim().isEmpty) return;
                        
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          // Add our UID to the receiver's unread list
                          await FirebaseFirestore.instance
                              .collection('chai_matches')
                              .doc(widget.uid)
                              .set({
                            'unreadMessagesFrom': FieldValue.arrayUnion([currentUser.uid])
                          }, SetOptions(merge: true));
                        }
                        
                        _messageController.clear();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message sent!')),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(CupertinoIcons.smiley, color: Colors.grey, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
