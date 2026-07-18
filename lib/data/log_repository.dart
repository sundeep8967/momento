import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_compress/video_compress.dart';
import 'cloudinary_service.dart';
import 'local_cache.dart';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class DayLog {
  final String id;
  final String date;
  final bool isClosed;
  final DateTime? closedAt;
  final int clipCount;
  final String? thumbnailUrl;

  DayLog({
    required this.id,
    required this.date,
    required this.isClosed,
    this.closedAt,
    required this.clipCount,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'isClosed': isClosed,
        'closedAt': closedAt?.toIso8601String(),
        'clipCount': clipCount,
        'thumbnailUrl': thumbnailUrl,
      };

  factory DayLog.fromMap(String id, Map<String, dynamic> map) => DayLog(
        id: id,
        date: map['date'] ?? id,
        isClosed: map['isClosed'] ?? false,
        closedAt: map['closedAt'] != null ? DateTime.tryParse(map['closedAt']) : null,
        clipCount: map['clipCount'] ?? 0,
        thumbnailUrl: map['thumbnailUrl'],
      );
}

class DayClip {
  final String id;
  final String cloudUrl;
  final String? localPath;
  final DateTime timestamp;
  final int order;
  final String? caption;

  DayClip({
    required this.id,
    required this.cloudUrl,
    this.localPath,
    required this.timestamp,
    required this.order,
    this.caption,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cloudUrl': cloudUrl,
        'localPath': localPath,
        'timestamp': timestamp.toIso8601String(),
        'order': order,
        'caption': caption,
      };

  factory DayClip.fromMap(Map<String, dynamic> map) => DayClip(
        id: map['id'] ?? '',
        cloudUrl: map['cloudUrl'] ?? '',
        localPath: map['localPath'],
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

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository._internal();
});

class LogRepository {
  // Keep instance for legacy compatibility during migration
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
    final clipId = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Save locally to permanent docs dir
    final docsDir = await getApplicationDocumentsDirectory();
    final persistentPath = '${docsDir.path}/clip_$clipId.mp4';
    await File(localFilePath).copy(persistentPath);

    // 2. Create the clip doc instantly
    final clip = DayClip(
      id: clipId,
      cloudUrl: '', // Will be updated by background task
      localPath: persistentPath,
      timestamp: DateTime.now(),
      order: log.clipCount,
      caption: caption,
    );
    
    final batch = _db.batch();
    batch.set(
      _logsRef(uid).doc(log.id).collection('clips').doc(clipId),
      clip.toMap(),
    );
    batch.update(_logsRef(uid).doc(log.id), {
      'clipCount': FieldValue.increment(1),
    });
    
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

    // 3. Start background upload without awaiting
    _uploadClipBackground(persistentPath, uid, log.id, clipId);
  }

  Future<void> _uploadClipBackground(String localFilePath, String uid, String logId, String clipId) async {
    try {
      final mediaInfo = await VideoCompress.compressVideo(
        localFilePath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );
      final uploadPath = mediaInfo?.file?.path ?? localFilePath;
      
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
      final apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
      final apiSecret = dotenv.env['CLOUDINARY_API_SECRET']!;

      final cloudUrl = await Isolate.run(() async {
        return await CloudinaryService.uploadRawVideo(
          localFilePath: uploadPath,
          cloudName: cloudName,
          apiKey: apiKey,
          apiSecret: apiSecret,
        );
      });
      
      try {
        await VideoCompress.deleteAllCache();
      } catch (_) {}

      final thumbnailUrl = cloudUrl.replaceAll(RegExp(r'\.mp4|\.webm|\.mov', caseSensitive: false), '.jpg');
      
      final batch = _db.batch();
      batch.update(
        _logsRef(uid).doc(logId).collection('clips').doc(clipId),
        {'cloudUrl': cloudUrl},
      );
      batch.update(
        _logsRef(uid).doc(logId),
        {'thumbnailUrl': thumbnailUrl},
      );
      await batch.commit();
    } catch (e) {
      // Background upload failed
    }
  }

  Future<List<DayLog>> getCachedMyLogs() async {
    return await LocalCache.instance.getCachedMyLogs();
  }

  Future<List<DayLog>> getMyDayLogs() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _logsRef(uid).orderBy('date', descending: true).limit(60).get();
    final logs = snap.docs
        .map((d) => DayLog.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
    await LocalCache.instance.cacheMyLogs(logs);
    return logs;
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

  /// Called when user taps "Send to Squad" from the OwnLogViewerScreen.
  /// Fetches current mutual friends and closes + shares the log immediately.
  Future<void> manualShareLog(String logId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    // Get mutual friend UIDs for the viewers list
    final snap = await _db
        .collection('friendships')
        .where('users', arrayContains: uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    final friendUids = snap.docs
        .map((d) => (d.data()['users'] as List).cast<String>().firstWhere((u) => u != uid, orElse: () => ''))
        .where((u) => u.isNotEmpty)
        .toList();

    final logDoc = await _logsRef(uid).doc(logId).get();
    if (!logDoc.exists) throw Exception('Log not found');
    final log = DayLog.fromMap(logDoc.id, logDoc.data() as Map<String, dynamic>);
    if (log.isClosed) throw Exception('Already sent');
    if (log.clipCount == 0) throw Exception('No clips to send');

    await _closeAndShareLog(log, friendUids);
  }

  Future<void> _closeAndShareLog(DayLog log, List<String> viewerUids) async {
    final uid = _uid;
    if (uid == null) return;
    final clips = await getMyClipsForLog(log.id);
    if (clips.isEmpty) return;
    final userDoc = await _db.collection('users').doc(uid).get();
    final username = (userDoc.data()?['username'] as String?) ?? 'unknown';
    final viewersMap = <String, dynamic>{};
    // Always add self as a viewer — your own day appears in your own Squad ring
    viewersMap[uid] = {'viewedAt': null, 'lastClipIndex': 0};
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
