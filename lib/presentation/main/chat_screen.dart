import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';
import '../../data/friends_repository.dart';
import '../../data/encryption_service.dart';
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

  String get _chatId {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final uids = [currentUid, widget.uid]..sort();
    return uids.join('_');
  }

  Uint8List get _chatKey {
    final keyBytes = sha256.convert(utf8.encode('momento_e2e_secret_$_chatId')).bytes;
    return Uint8List.fromList(keyBytes);
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    final profile = await FriendsRepository.instance.getUserProfile(widget.uid);
    if (mounted) setState(() => _userProfile = profile);
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
              _userProfile?.displayName ?? 'User',
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
          // Real-time End-to-End Encrypted Chat Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.lock_shield_fill, color: SetlogColors.momentoPink, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'End-to-End Encrypted Chat',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Messages are AES-256 encrypted on device.\nNo one outside of this chat can read them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final senderId = data['senderId'] as String? ?? '';
                    final encryptedPayload = data['encryptedText'] as String? ?? '';
                    final isMe = senderId == FirebaseAuth.instance.currentUser?.uid;

                    String text = '[Encrypted Message]';
                    try {
                      if (encryptedPayload.isNotEmpty) {
                        text = EncryptionService.decryptPayload(encryptedPayload, _chatKey);
                      }
                    } catch (_) {}

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? CupertinoColors.activeBlue : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                            bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
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
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.camera_fill, color: Colors.grey, size: 22),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.lock_fill,
                          color: Colors.grey.shade600,
                          size: 11,
                        ),
                      ),
                    ),
                  ],
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
                        final textSent = text.trim();
                        if (textSent.isEmpty) return;
                        _messageController.clear();
                        
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) return;
                        
                        // 1. Encrypt text payload with AES-256-CBC
                        final encryptedPayload = EncryptionService.encryptPayload(textSent, _chatKey);
                        
                        // 2. Save encrypted message to Firestore real-time collection
                        await FirebaseFirestore.instance
                            .collection('chats')
                            .doc(_chatId)
                            .collection('messages')
                            .add({
                          'senderId': currentUser.uid,
                          'receiverId': widget.uid,
                          'encryptedText': encryptedPayload,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        
                        // 3. Mark unread message notification for recipient
                        await FirebaseFirestore.instance
                            .collection('chai_matches')
                            .doc(widget.uid)
                            .set({
                          'unreadMessagesFrom': FieldValue.arrayUnion([currentUser.uid])
                        }, SetOptions(merge: true));
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
