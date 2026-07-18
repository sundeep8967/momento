import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'friends_repository.dart';

class DirectSnap {
  final String id;
  final String senderUid;
  final String senderUsername;
  final String? groupName; // Null if it's a direct message
  final String videoUrl; // Now acts as mediaUrl
  final DateTime timestamp;
  final bool isViewed;
  final bool isVideo;

  DirectSnap({
    required this.id,
    required this.senderUid,
    required this.senderUsername,
    this.groupName,
    required this.videoUrl,
    required this.timestamp,
    required this.isViewed,
    this.isVideo = true,
  });

  factory DirectSnap.fromFirestore(String id, Map<String, dynamic> data) => DirectSnap(
        id: id,
        senderUid: data['senderUid'] ?? '',
        senderUsername: data['senderUsername'] ?? '',
        groupName: data['groupName'],
        videoUrl: data['videoUrl'] ?? '',
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isViewed: data['isViewed'] ?? false,
        isVideo: data['isVideo'] ?? true, // Default to true for backwards compatibility
      );
}

final snapRepositoryProvider = Provider<SnapRepository>((ref) {
  return SnapRepository._internal();
});

class SnapRepository {
  SnapRepository._internal();
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  
  String? get _uid => _auth.currentUser?.uid;

  // Fan-out model: write the snap to every recipient's inbox.
  Future<void> sendSnap({
    required String videoUrl,
    required bool isVideo,
    required List<String> friendUids,
    required List<Group> groups,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    
    final senderDoc = await _db.collection('users').doc(uid).get();
    final senderUsername = senderDoc.data()?['username'] ?? 'Unknown';

    final batch = _db.batch();

    // 1. Send direct to friends (including self)
    final recipients = Set<String>.from(friendUids);
    recipients.add(uid); // Ensure sender always gets a copy in their own inbox
    
    for (final friendUid in recipients) {
      final snapRef = _db.collection('users').doc(friendUid).collection('inbox').doc();
      batch.set(snapRef, {
        'senderUid': uid,
        'senderUsername': senderUsername,
        'groupName': null,
        'videoUrl': videoUrl,
        'isVideo': isVideo,
        'timestamp': FieldValue.serverTimestamp(),
        'isViewed': false,
      });
    }

    // 2. Send to groups (fan out to all members)
    for (final group in groups) {
      for (final memberUid in group.members) {
        // We do NOT skip the sender here anymore, so they get the group snap too.
        final snapRef = _db.collection('users').doc(memberUid).collection('inbox').doc();
        batch.set(snapRef, {
          'senderUid': uid,
          'senderUsername': senderUsername,
          'groupName': group.name,
          'videoUrl': videoUrl,
          'isVideo': isVideo,
          'timestamp': FieldValue.serverTimestamp(),
          'isViewed': false,
        });
      }
    }

    await batch.commit();
  }

  Stream<List<DirectSnap>> getInboxStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    
    return _db
        .collection('users')
        .doc(uid)
        .collection('inbox')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DirectSnap.fromFirestore(d.id, d.data())).toList());
  }

  Future<void> markSnapAsViewed(String snapId) async {
    final uid = _uid;
    if (uid == null) return;
    
    await _db
        .collection('users')
        .doc(uid)
        .collection('inbox')
        .doc(snapId)
        .update({'isViewed': true});
  }
}
