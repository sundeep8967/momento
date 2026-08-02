import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'friends_repository.dart';
import 'push_notification_service.dart';

class DirectSnap {
  final String id;
  final String senderUid;
  final String senderUsername;
  final String? groupName; // Null if it's a direct message
  final String videoUrl; // Now acts as mediaUrl
  final DateTime timestamp;
  final bool isViewed;
  final bool isVideo;
  final double? lat;
  final double? lng;
  final bool isFrontCamera;

  DirectSnap({
    required this.id,
    required this.senderUid,
    required this.senderUsername,
    this.groupName,
    required this.videoUrl,
    required this.timestamp,
    required this.isViewed,
    this.isVideo = true,
    this.lat,
    this.lng,
    this.isFrontCamera = false,
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
        lat: (data['lat'] as num?)?.toDouble(),
        lng: (data['lng'] as num?)?.toDouble(),
        isFrontCamera: data['isFrontCamera'] ?? false,
      );
}

final snapRepositoryProvider = Provider<SnapRepository>((ref) {
  return SnapRepository._internal();
});

final groupedInboxStreamProvider = StreamProvider<List<List<DirectSnap>>>((ref) {
  final snapRepo = ref.watch(snapRepositoryProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  
  return snapRepo.getInboxStream().map((allSnaps) {
    // Group snaps by senderUid or groupName
    final Map<String, List<DirectSnap>> grouped = {};
    for (final snap in allSnaps) {
      final key = snap.groupName != null && snap.groupName!.isNotEmpty
          ? 'group:${snap.groupName}'
          : snap.senderUid;
      grouped.putIfAbsent(key, () => []).add(snap);
    }

    final entries = grouped.values.toList();
    entries.sort((a, b) {
      final aNew = a.any((s) => !s.isViewed && s.senderUid != uid);
      final bNew = b.any((s) => !s.isViewed && s.senderUid != uid);
      if (aNew != bNew) return aNew ? -1 : 1;
      return b.first.timestamp.compareTo(a.first.timestamp);
    });
    
    return entries;
  });
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
    double? lat,
    double? lng,
    bool isFrontCamera = false,
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
        'isFrontCamera': isFrontCamera,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
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
          'isFrontCamera': isFrontCamera,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        });
      }
    }

    await batch.commit();

    // Fire push notifications to all recipients (skip sender's own copy)
    final notifUids = <String>{
      ...friendUids,
      for (final g in groups) ...g.members,
    }..remove(uid); // sender doesn't need a notification for their own snap

    for (final recipientUid in notifUids) {
      try {
        final recipientDoc = await _db.collection('users').doc(recipientUid).get();
        final fcmToken = recipientDoc.data()?['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await PushNotificationService.instance.sendPushNotification(
            targetToken: fcmToken,
            title: '📸 @$senderUsername sent you a Momento!',
            body: isVideo ? 'Tap to watch before it disappears.' : 'Tap to view before it disappears.',
          );
        }
      } catch (_) {
        // Never let a failed notification break the snap send
      }
    }
  }

  // ── Public Local Snaps ──

  Future<void> sendLocalSnap({
    required String videoUrl,
    required bool isVideo,
    required double lat,
    required double lng,
    bool isFrontCamera = false,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    
    final senderDoc = await _db.collection('users').doc(uid).get();
    final senderUsername = senderDoc.data()?['username'] ?? 'Unknown';

    final snapRef = _db.collection('local_snaps').doc();
    await snapRef.set({
      'senderUid': uid,
      'senderUsername': senderUsername,
      'groupName': null,
      'videoUrl': videoUrl,
      'isVideo': isVideo,
      'timestamp': FieldValue.serverTimestamp(),
      'isViewed': false,
      'isFrontCamera': isFrontCamera,
      'lat': lat,
      'lng': lng,
    });
  }

  Stream<List<DirectSnap>> getLocalSnapsStream() {
    return _db
        .collection('local_snaps')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DirectSnap.fromFirestore(d.id, d.data())).toList());
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
