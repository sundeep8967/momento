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
  final String? recipientUid;

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
    this.recipientUid,
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
        recipientUid: data['recipientUid'],
      );
}

final snapRepositoryProvider = Provider<SnapRepository>((ref) {
  return SnapRepository._internal();
});

// Tracks UIDs and Group names currently being sent a snap for UI loading states
final sendingSnapsProvider = StateProvider<Set<String>>((ref) => <String>{});

final groupedInboxStreamProvider = StreamProvider<List<List<DirectSnap>>>((ref) {
  final snapRepo = ref.watch(snapRepositoryProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  
  return snapRepo.getInboxStream().map((allSnaps) {
    // Group snaps by partnerUid or groupName
    final Map<String, List<DirectSnap>> grouped = {};
    for (final snap in allSnaps) {
      final String partnerUid = snap.senderUid == uid 
          ? (snap.recipientUid ?? uid!) 
          : snap.senderUid;
      final key = snap.groupName != null && snap.groupName!.isNotEmpty
          ? 'group:${snap.groupName}'
          : partnerUid;
      grouped.putIfAbsent(key, () => []).add(snap);
    }

    final unreadBucket = <List<DirectSnap>>[];
    final readBucket = <List<DirectSnap>>[];

    for (final entry in grouped.values) {
      final isNew = entry.any((s) => !s.isViewed && s.senderUid != uid);
      if (isNew) {
        unreadBucket.add(entry);
      } else {
        readBucket.add(entry);
      }
    }

    unreadBucket.sort((a, b) => b.first.timestamp.compareTo(a.first.timestamp));
    readBucket.sort((a, b) => b.first.timestamp.compareTo(a.first.timestamp));

    return [...unreadBucket, ...readBucket];
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

    // 1. Send direct to friends
    for (final friendUid in friendUids) {
      if (friendUid == uid) {
        // Self-snap: unread copy for self
        final snapRef = _db.collection('users').doc(uid).collection('inbox').doc();
        batch.set(snapRef, {
          'senderUid': uid,
          'senderUsername': senderUsername,
          'recipientUid': uid,
          'groupName': null,
          'videoUrl': videoUrl,
          'isVideo': isVideo,
          'timestamp': FieldValue.serverTimestamp(),
          'isViewed': false,
          'isFrontCamera': isFrontCamera,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        });
        continue;
      }

      // Copy for the recipient (unread)
      final recipientSnapRef = _db.collection('users').doc(friendUid).collection('inbox').doc();
      batch.set(recipientSnapRef, {
        'senderUid': uid,
        'senderUsername': senderUsername,
        'recipientUid': friendUid,
        'groupName': null,
        'videoUrl': videoUrl,
        'isVideo': isVideo,
        'timestamp': FieldValue.serverTimestamp(),
        'isViewed': false,
        'isFrontCamera': isFrontCamera,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });

      // Copy for the sender (viewed/sent marker)
      final senderSnapRef = _db.collection('users').doc(uid).collection('inbox').doc();
      batch.set(senderSnapRef, {
        'senderUid': uid,
        'senderUsername': senderUsername,
        'recipientUid': friendUid,
        'groupName': null,
        'videoUrl': videoUrl,
        'isVideo': isVideo,
        'timestamp': FieldValue.serverTimestamp(),
        'isViewed': true, // Already viewed by sender
        'isFrontCamera': isFrontCamera,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
    }

    // If friendUids was empty, write a self snap
    if (friendUids.isEmpty) {
      final snapRef = _db.collection('users').doc(uid).collection('inbox').doc();
      batch.set(snapRef, {
        'senderUid': uid,
        'senderUsername': senderUsername,
        'recipientUid': uid,
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
        final snapRef = _db.collection('users').doc(memberUid).collection('inbox').doc();
        batch.set(snapRef, {
          'senderUid': uid,
          'senderUsername': senderUsername,
          'recipientUid': memberUid,
          'groupName': group.name,
          'videoUrl': videoUrl,
          'isVideo': isVideo,
          'timestamp': FieldValue.serverTimestamp(),
          'isViewed': memberUid == uid, // Sender's own group copy is viewed
          'isFrontCamera': isFrontCamera,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        });
      }
    }

    await batch.commit();

    // Trigger pairwise streak updates asynchronously (do not await to keep send fast)
    if (friendUids.isNotEmpty) {
      _updatePairwiseStreaks(uid, friendUids);
    }

    // Fire push notifications to all recipients concurrently (not sequentially)
    final notifUids = <String>{
      ...friendUids,
      for (final g in groups) ...g.members,
    }..remove(uid); // sender doesn't need a notification for their own snap

    // Fetch all recipient docs in parallel, then fire all push calls in parallel
    await Future.wait(
      notifUids.map((recipientUid) async {
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
      }),
    );
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

  Future<void> _updatePairwiseStreaks(String senderUid, List<String> friendUids) async {
    for (final friendUid in friendUids) {
      if (friendUid == senderUid) continue;
      
      final sorted = [senderUid, friendUid]..sort();
      final docId = '${sorted[0]}__${sorted[1]}';
      final docRef = _db.collection('friendships').doc(docId);
      
      try {
        await _db.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          if (!snap.exists) return;
          
          final data = snap.data()!;
          final now = DateTime.now();
          
          Map<String, dynamic> lastSnaps = {};
          if (data['lastSnaps'] != null) {
            lastSnaps = Map<String, dynamic>.from(data['lastSnaps']);
          }
          
          final lastSnapOtherRaw = lastSnaps[friendUid];
          DateTime? lastSnapOther;
          if (lastSnapOtherRaw is Timestamp) {
            lastSnapOther = lastSnapOtherRaw.toDate();
          }
          
          final lastIncrementRaw = data['lastStreakIncrement'];
          DateTime? lastIncrement;
          if (lastIncrementRaw is Timestamp) {
            lastIncrement = lastIncrementRaw.toDate();
          }
          
          int currentStreak = data['streakCount'] ?? 0;
          
          bool isOtherActive = lastSnapOther != null && now.difference(lastSnapOther).inHours <= 36;
          
          lastSnaps[senderUid] = FieldValue.serverTimestamp();
          
          if (isOtherActive) {
            // 12-hour cooldown
            if (lastIncrement == null || now.difference(lastIncrement).inHours >= 12) {
              currentStreak++;
              tx.update(docRef, {
                'lastSnaps': lastSnaps,
                'streakCount': currentStreak,
                'lastStreakIncrement': FieldValue.serverTimestamp(),
              });
              return;
            }
          } else {
            // Other hasn't snapped in 36 hours. Streak broken.
            currentStreak = 0;
          }
          
          tx.update(docRef, {
            'lastSnaps': lastSnaps,
            if (!isOtherActive) 'streakCount': currentStreak,
            if (!isOtherActive) 'lastStreakIncrement': null,
          });
        });
      } catch (e) {
        // fail silently for background streak update
      }
    }
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
