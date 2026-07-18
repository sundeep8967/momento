import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart';

class UserProfile {
  final String uid;
  final String username;
  final String displayName;
  final String photoUrl;
  final DateTime? createdAt;
  final int currentStreak;
  final int longestStreak;
  final String? lastLogDate;

  UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl = '',
    this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLogDate,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) => UserProfile(
        uid: uid,
        username: map['username'] ?? '',
        displayName: map['displayName'] ?? '',
        photoUrl: map['photoUrl'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        currentStreak: map['currentStreak'] ?? 0,
        longestStreak: map['longestStreak'] ?? 0,
        lastLogDate: map['lastLogDate'],
      );
}

class Friendship {
  final String id;
  final List<String> users;
  final String requestedBy;
  final String status;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.users,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromFirestore(String id, Map<String, dynamic> data) => Friendship(
        id: id,
        users: List<String>.from(data['users'] ?? []),
        requestedBy: data['requestedBy'] ?? '',
        status: data['status'] ?? 'pending',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class FriendsRepository {
  static final FriendsRepository instance = FriendsRepository._internal();
  FriendsRepository._internal();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  String _friendshipId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Future<UserProfile?> searchByUsername(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase().trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return UserProfile.fromMap(doc.id, doc.data());
  }

  Future<void> sendFriendRequest(String targetUid) async {
    final uid = _uid;
    if (uid == null) return;
    final docId = _friendshipId(uid, targetUid);
    await _db.collection('friendships').doc(docId).set({
      'users': [uid, targetUid],
      'requestedBy': uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Client-side push notification
    try {
      final myProfile = await getMyProfile();
      final targetDoc = await _db.collection('users').doc(targetUid).get();
      final fcmToken = targetDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken != null && fcmToken.isNotEmpty && myProfile != null) {
        await PushNotificationService.instance.sendPushNotification(
          targetToken: fcmToken,
          title: 'New Friend Request',
          body: '@${myProfile.username} wants to be your friend!',
        );
      }
    } catch (e) {
      // Ignore notification failures so the request still succeeds
    }
  }

  Future<void> acceptRequest(String targetUid) async {
    final uid = _uid;
    if (uid == null) return;
    final docId = _friendshipId(uid, targetUid);
    await _db.collection('friendships').doc(docId).update({'status': 'accepted'});
  }

  Future<void> declineOrRemove(String targetUid) async {
    final uid = _uid;
    if (uid == null) return;
    final docId = _friendshipId(uid, targetUid);
    await _db.collection('friendships').doc(docId).delete();
  }

  Future<List<Friendship>> getMyFriendships() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _db
        .collection('friendships')
        .where('users', arrayContains: uid)
        .get();
    return snap.docs.map((d) => Friendship.fromFirestore(d.id, d.data())).toList();
  }

  Future<List<Friendship>> getPendingRequests() async {
    final uid = _uid;
    if (uid == null) return [];
    final all = await getMyFriendships();
    return all.where((f) => f.status == 'pending' && f.requestedBy != uid).toList();
  }

  Future<List<Friendship>> getSentRequests() async {
    final uid = _uid;
    if (uid == null) return [];
    final all = await getMyFriendships();
    return all.where((f) => f.status == 'pending' && f.requestedBy == uid).toList();
  }

  Future<List<String>> getMutualFriendUids() async {
    final uid = _uid;
    if (uid == null) return [];
    final all = await getMyFriendships();
    return all
        .where((f) => f.status == 'accepted')
        .map((f) => f.users.firstWhere((u) => u != uid))
        .toList();
  }

  Future<List<UserProfile>> getMutualFriends() async {
    final uids = await getMutualFriendUids();
    if (uids.isEmpty) return [];
    final profiles = <UserProfile>[];
    for (final uid in uids) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) profiles.add(UserProfile.fromMap(doc.id, doc.data()!));
    }
    return profiles;
  }

  Future<void> saveUserProfile({
    required String username,
    required String displayName,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'username': username.toLowerCase().trim(),
      'displayName': displayName,
      'email': _auth.currentUser?.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isUsernameTaken(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase().trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<UserProfile?> getMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateProfilePicture(String photoUrl) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'photoUrl': photoUrl});
  }

  Future<void> deleteAccount() async {
    final uid = _uid;
    if (uid == null) return;
    
    // Delete user profile document
    await _db.collection('users').doc(uid).delete();
    
    // Delete auth account
    await _auth.currentUser?.delete();
  }

  Future<void> blockUser(String targetUid) async {
    final uid = _uid;
    if (uid == null) return;
    final blockId = '${uid}_$targetUid';
    
    // Save to blocks collection
    await _db.collection('blocks').doc(blockId).set({
      'blocker': uid,
      'blocked': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Remove friendship if exists
    await declineOrRemove(targetUid);
  }
}
