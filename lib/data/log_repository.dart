import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:video_compress/video_compress.dart';
import 'cloudinary_service.dart';
import 'local_cache.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class DayLog {
  final String id;
  final String date;
  final bool isClosed;
  final DateTime? closedAt;
  final int clipCount;

  DayLog({
    required this.id,
    required this.date,
    required this.isClosed,
    this.closedAt,
    required this.clipCount,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'isClosed': isClosed,
        'closedAt': closedAt?.toIso8601String(),
        'clipCount': clipCount,
      };

  factory DayLog.fromMap(String id, Map<String, dynamic> map) => DayLog(
        id: id,
        date: map['date'] ?? id,
        isClosed: map['isClosed'] ?? false,
        closedAt: map['closedAt'] != null ? DateTime.tryParse(map['closedAt']) : null,
        clipCount: map['clipCount'] ?? 0,
      );
}

class DayClip {
  final String id;
  final String cloudUrl;
  final DateTime timestamp;
  final int order;
  final String? caption;

  DayClip({
    required this.id,
    required this.cloudUrl,
    required this.timestamp,
    required this.order,
    this.caption,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cloudUrl': cloudUrl,
        'timestamp': timestamp.toIso8601String(),
        'order': order,
        'caption': caption,
      };

  factory DayClip.fromMap(Map<String, dynamic> map) => DayClip(
        id: map['id'] ?? '',
        cloudUrl: map['cloudUrl'] ?? '',
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
        order: map['order'] ?? 0,
        caption: map['caption'],
      );
}

class SharedLog {
  final String id;
  final String ownerUid;
  final String ownerUsername;
  final String date;
  final List<SharedClip> clips;
  final DateTime expiresAt;
  final Map<String, dynamic> viewers;
  final Map<String, dynamic> reactions;

  SharedLog({
    required this.id,
    required this.ownerUid,
    required this.ownerUsername,
    required this.date,
    required this.clips,
    required this.expiresAt,
    required this.viewers,
    required this.reactions,
  });

  bool get isViewedByMe {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final v = viewers[uid];
    if (v == null) return false;
    return v['viewedAt'] != null;
  }

  factory SharedLog.fromFirestore(String id, Map<String, dynamic> data) => SharedLog(
        id: id,
        ownerUid: data['ownerUid'] ?? '',
        ownerUsername: data['ownerUsername'] ?? '',
        date: data['date'] ?? '',
        clips: (data['clips'] as List<dynamic>? ?? [])
            .map((c) => SharedClip.fromMap(c as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
        expiresAt: data['expiresAt'] is Timestamp
            ? (data['expiresAt'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(hours: 48)),
        viewers: Map<String, dynamic>.from(data['viewers'] ?? {}),
        reactions: Map<String, dynamic>.from(data['reactions'] ?? {}),
      );
}

class SharedClip {
  final String id;
  final String cloudUrl;
  final DateTime timestamp;
  final int order;
  final String? caption;

  SharedClip({
    required this.id,
    required this.cloudUrl,
    required this.timestamp,
    required this.order,
    this.caption,
  });

  factory SharedClip.fromMap(Map<String, dynamic> map) => SharedClip(
        id: map['id'] ?? '',
        cloudUrl: map['cloudUrl'] ?? '',
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
        order: map['order'] ?? 0,
        caption: map['caption'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'cloudUrl': cloudUrl,
        'timestamp': timestamp.toIso8601String(),
        'order': order,
        'caption': caption,
      };
}

// ─────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────

class LogRepository {
  static final LogRepository instance = LogRepository._internal();
  LogRepository._internal();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? get _uid => _auth.currentUser?.uid;

  CollectionReference _logsRef(String uid) =>
      _db.collection('users').doc(uid).collection('logs');

  Future<DayLog> getOrCreateTodaysLog() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final today = _today;
    final docRef = _logsRef(uid).doc(today);
    final snap = await docRef.get();
    if (snap.exists) {
      return DayLog.fromMap(snap.id, snap.data() as Map<String, dynamic>);
    }
    final newLog = DayLog(id: today, date: today, isClosed: false, clipCount: 0);
    await docRef.set(newLog.toMap());
    return newLog;
  }

  Future<void> addClipToTodaysLog(String localFilePath, {String? caption}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final log = await getOrCreateTodaysLog();
    
    // Compress video to save bandwidth and Cloudinary storage
    final mediaInfo = await VideoCompress.compressVideo(
      localFilePath,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false,
    );
    final uploadPath = mediaInfo?.file?.path ?? localFilePath;
    
    final cloudUrl = await CloudinaryService.uploadRawVideo(uploadPath);
    
    // Clean up compression cache to avoid storage bloat
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}

    final clipId = DateTime.now().millisecondsSinceEpoch.toString();
    final clip = DayClip(
      id: clipId,
      cloudUrl: cloudUrl,
      timestamp: DateTime.now(),
      order: log.clipCount,
      caption: caption,
    );
    final batch = _db.batch();
    batch.set(
      _logsRef(uid).doc(log.id).collection('clips').doc(clipId),
      clip.toMap(),
    );
    batch.update(_logsRef(uid).doc(log.id), {'clipCount': FieldValue.increment(1)});
    
    // Evaluate Streaks if this is the first clip of the day
    if (log.clipCount == 0) {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final lastLogDate = data['lastLogDate'] as String?;
        int currentStreak = data['currentStreak'] as int? ?? 0;
        int longestStreak = data['longestStreak'] as int? ?? 0;
        
        if (lastLogDate != null) {
          final lastDate = DateFormat('yyyy-MM-dd').parse(lastLogDate);
          final todayDate = DateFormat('yyyy-MM-dd').parse(_today);
          final difference = todayDate.difference(lastDate).inDays;
          
          if (difference == 1) {
            // Consecutive day
            currentStreak += 1;
          } else if (difference > 1) {
            // Streak broken
            currentStreak = 1;
          }
        } else {
          // First ever log
          currentStreak = 1;
        }
        
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        
        batch.update(_db.collection('users').doc(uid), {
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'lastLogDate': _today,
        });
      }
    }
    
    await batch.commit();
  }

  Future<List<DayLog>> getMyDayLogs() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _logsRef(uid).orderBy('date', descending: true).limit(60).get();
    return snap.docs
        .map((d) => DayLog.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<DayClip>> getMyClipsForLog(String logId) async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _logsRef(uid).doc(logId).collection('clips').orderBy('order').get();
    return snap.docs.map((d) => DayClip.fromMap(d.data())).toList();
  }

  Future<void> checkAndCloseExpiredLogs(List<String> mutualFriendUids) async {
    final uid = _uid;
    if (uid == null) return;
    final today = _today;
    final snap = await _logsRef(uid).where('isClosed', isEqualTo: false).get();
    for (final doc in snap.docs) {
      final log = DayLog.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      if (log.date != today && log.clipCount > 0) {
        await _closeAndShareLog(log, mutualFriendUids);
      }
    }
  }

  Future<void> _closeAndShareLog(DayLog log, List<String> viewerUids) async {
    final uid = _uid;
    if (uid == null) return;
    final clips = await getMyClipsForLog(log.id);
    if (clips.isEmpty) return;
    final userDoc = await _db.collection('users').doc(uid).get();
    final username = (userDoc.data()?['username'] as String?) ?? 'unknown';
    final viewersMap = <String, dynamic>{};
    for (final vUid in viewerUids) {
      viewersMap[vUid] = {'viewedAt': null, 'lastClipIndex': 0};
    }
    final logDate = DateFormat('yyyy-MM-dd').parse(log.date);
    final midnight = DateTime(logDate.year, logDate.month, logDate.day + 1);
    final expiresAt = midnight.add(const Duration(hours: 48));
    final shareId = '${uid}_${log.date}';
    final batch = _db.batch();
    batch.set(
      _db.collection('sharedLogs').doc(shareId),
      {
        'ownerUid': uid,
        'ownerUsername': username,
        'date': log.date,
        'clips': clips.map((c) => c.toMap()).toList(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewers': viewersMap,
        'reactions': {},
      },
    );
    batch.update(_logsRef(uid).doc(log.id), {
      'isClosed': true,
      'closedAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
  }

  Future<List<SharedLog>> getCachedFriendsSharedLogs() async {
    return await LocalCache.instance.getCachedSharedLogs();
  }

  Future<List<SharedLog>> getFriendsSharedLogs() async {
    final uid = _uid;
    if (uid == null) {
      await LocalCache.instance.cacheSharedLogs([]);
      return [];
    }
    final snap = await _db
        .collection('sharedLogs')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('expiresAt', descending: false)
        .limit(30)
        .get();
    final logs = snap.docs
        .map((d) => SharedLog.fromFirestore(d.id, d.data()))
        .where((log) => log.viewers.containsKey(uid))
        .toList();
        
    await LocalCache.instance.cacheSharedLogs(logs);
    return logs;
  }

  Future<void> markLogViewed(String shareId, int lastClipIndex) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('sharedLogs').doc(shareId).update({
      'viewers.$uid': {'viewedAt': Timestamp.now(), 'lastClipIndex': lastClipIndex},
    });
  }

  Future<void> deleteClip(String logId, String clipId) async {
    final uid = _uid;
    if (uid == null) return;
    
    await _logsRef(uid).doc(logId).update({'clipCount': FieldValue.increment(-1)});
    await _logsRef(uid).doc(logId).collection('clips').doc(clipId).delete();
  }

  Future<void> addReaction(String shareId, String clipId, String emoji) async {
    final uid = _uid;
    if (uid == null) return;
    
    await _db.collection('sharedLogs').doc(shareId).set({
      'reactions': {
        clipId: {
          uid: emoji
        }
      }
    }, SetOptions(merge: true));
  }

  // Legacy
  Future<List<VideoLog>> getLogs() async => [];
}

class VideoLog {
  final String id;
  final String path;
  final DateTime timestamp;
  final String? cloudUrl;

  VideoLog({required this.id, required this.path, required this.timestamp, this.cloudUrl});

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'timestamp': timestamp.toIso8601String(),
        'cloudUrl': cloudUrl,
      };

  factory VideoLog.fromJson(Map<String, dynamic> json) => VideoLog(
        id: json['id'],
        path: json['path'],
        timestamp: DateTime.parse(json['timestamp']),
        cloudUrl: json['cloudUrl'],
      );
}
