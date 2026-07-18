import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart';

class Reaction {
  final String emoji;
  final DateTime reactedAt;
  final String reactorUid;
  final String reactorUsername;

  Reaction({
    required this.emoji,
    required this.reactedAt,
    required this.reactorUid,
    required this.reactorUsername,
  });

  factory Reaction.fromFirestore(Map<String, dynamic> data) => Reaction(
        emoji: data['emoji'] ?? '❤️',
        reactedAt: (data['reactedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        reactorUid: data['reactorUid'] ?? '',
        reactorUsername: data['reactorUsername'] ?? '',
      );
}

class ReactionsRepository {
  static final ReactionsRepository instance = ReactionsRepository._internal();
  ReactionsRepository._internal();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference _clipReactionDoc(
          String shareId, String clipId, String uid) =>
      _db
          .collection('reactions')
          .doc(shareId)
          .collection('clips')
          .doc(clipId)
          .collection('reacts')
          .doc(uid);

  Future<void> addReaction({
    required String shareId,
    required String clipId,
    required String emoji,
    required String reactorUsername,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _clipReactionDoc(shareId, clipId, uid).set({
      'emoji': emoji,
      'reactedAt': FieldValue.serverTimestamp(),
      'reactorUid': uid,
      'reactorUsername': reactorUsername,
    });

    // Send push notification to the owner of the shared log
    try {
      final shareDoc = await _db.collection('sharedLogs').doc(shareId).get();
      final ownerUid = shareDoc.data()?['ownerUid'] as String?;
      if (ownerUid != null && ownerUid != uid) {
        final ownerDoc = await _db.collection('users').doc(ownerUid).get();
        final fcmToken = ownerDoc.data()?['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Requires import 'push_notification_service.dart';
          await PushNotificationService.instance.sendPushNotification(
            targetToken: fcmToken,
            title: 'New Reaction',
            body: '@$reactorUsername reacted $emoji to your moment!',
          );
        }
      }
    } catch (e) {
      // Ignore notification errors
    }
  }

  Future<void> removeReaction({
    required String shareId,
    required String clipId,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _clipReactionDoc(shareId, clipId, uid).delete();
  }

  Stream<List<Reaction>> reactionsStream(String shareId, String clipId) {
    return _db
        .collection('reactions')
        .doc(shareId)
        .collection('clips')
        .doc(clipId)
        .collection('reacts')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Reaction.fromFirestore(d.data())).toList());
  }

  Future<Map<String, List<Reaction>>> getAllReactionsForLog(
      String shareId) async {
    final clipsSnap = await _db
        .collection('reactions')
        .doc(shareId)
        .collection('clips')
        .get();
    final result = <String, List<Reaction>>{};
    for (final clipDoc in clipsSnap.docs) {
      final reactsSnap =
          await clipDoc.reference.collection('reacts').get();
      result[clipDoc.id] =
          reactsSnap.docs.map((d) => Reaction.fromFirestore(d.data())).toList();
    }
    return result;
  }
}
