import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'friends_repository.dart';
import 'log_repository.dart';

class LocalCache {
  static final LocalCache instance = LocalCache._internal();
  LocalCache._internal();

  static const String _keyFriends = 'cached_friends';
  static const String _keySharedLogs = 'cached_shared_logs';

  Future<void> cacheFriends(List<UserProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = profiles.map((p) => {
        'uid': p.uid,
        'username': p.username,
        'displayName': p.displayName,
        'photoUrl': p.photoUrl,
        'currentStreak': p.currentStreak,
        'longestStreak': p.longestStreak,
        'lastLogDate': p.lastLogDate,
        'createdAt': p.createdAt?.millisecondsSinceEpoch,
      }).toList();
      await prefs.setString(_keyFriends, jsonEncode(jsonList));
    } catch (e) {
      // Ignore cache write errors
    }
  }

  Future<List<UserProfile>> getCachedFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFriends);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((map) {
        return UserProfile(
          uid: map['uid'],
          username: map['username'],
          displayName: map['displayName'],
          photoUrl: map['photoUrl'] ?? '',
          currentStreak: map['currentStreak'] ?? 0,
          longestStreak: map['longestStreak'] ?? 0,
          lastLogDate: map['lastLogDate'],
          createdAt: map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> cacheSharedLogs(List<SharedLog> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = logs.map((log) => {
        'id': log.id,
        'ownerUid': log.ownerUid,
        'ownerUsername': log.ownerUsername,
        'date': log.date,
        'expiresAt': log.expiresAt.millisecondsSinceEpoch,
        'clips': log.clips.map((c) => c.toMap()).toList(),
        'viewers': log.viewers,
        'reactions': log.reactions,
      }).toList();
      await prefs.setString(_keySharedLogs, jsonEncode(jsonList));
    } catch (e) {
      // Ignore cache write errors
    }
  }

  Future<List<SharedLog>> getCachedSharedLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keySharedLogs);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((map) {
        return SharedLog(
          id: map['id'],
          ownerUid: map['ownerUid'],
          ownerUsername: map['ownerUsername'],
          date: map['date'],
          expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt']),
          clips: (map['clips'] as List<dynamic>?)?.map((c) => SharedClip.fromMap(Map<String, dynamic>.from(c))).toList() ?? [],
          viewers: Map<String, dynamic>.from(map['viewers'] ?? {}),
          reactions: Map<String, dynamic>.from(map['reactions'] ?? {}),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
