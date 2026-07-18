import 'dart:convert';
import 'package:isar/isar.dart';
import '../main.dart'; // To access global `isar` instance
import 'friends_repository.dart';
import 'log_repository.dart';
import 'models/isar_models.dart';

class LocalCache {
  static final LocalCache instance = LocalCache._internal();
  LocalCache._internal();

  Future<void> cacheFriends(List<UserProfile> profiles) async {
    try {
      final isarProfiles = profiles.map((p) => IsarUserProfile()
        ..uid = p.uid
        ..username = p.username
        ..displayName = p.displayName
        ..photoUrl = p.photoUrl
        ..currentStreak = p.currentStreak
        ..longestStreak = p.longestStreak
        ..lastLogDate = p.lastLogDate
      ).toList();

      await isar.writeTxn(() async {
        await isar.isarUserProfiles.putAll(isarProfiles);
      });
    } catch (e) {
      // Ignore cache write errors
    }
  }

  Future<List<UserProfile>> getCachedFriends() async {
    try {
      final isarProfiles = await isar.isarUserProfiles.where().findAll();
      return isarProfiles.map((p) => UserProfile(
        uid: p.uid,
        username: p.username,
        displayName: p.displayName,
        photoUrl: p.photoUrl ?? '',
        currentStreak: p.currentStreak,
        longestStreak: p.longestStreak,
        lastLogDate: p.lastLogDate,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> cacheSharedLogs(List<SharedLog> logs) async {
    try {
      final isarLogs = logs.map((log) {
        final clipsJson = jsonEncode(log.clips.map((c) => c.toMap()).toList());
        final viewersJson = jsonEncode(log.viewers);
        final reactionsJson = jsonEncode(log.reactions);

        return IsarSharedLog()
          ..shareId = log.id
          ..ownerUid = log.ownerUid
          ..ownerUsername = log.ownerUsername
          ..date = log.date
          ..expiresAt = log.expiresAt
          ..isViewedByMe = log.isViewedByMe
          ..clipsJson = clipsJson
          ..viewersJson = viewersJson
          ..reactionsJson = reactionsJson;
      }).toList();

      await isar.writeTxn(() async {
        await isar.isarSharedLogs.putAll(isarLogs);
      });
    } catch (e) {
      // Ignore cache write errors
    }
  }

  Future<List<SharedLog>> getCachedSharedLogs() async {
    try {
      final isarLogs = await isar.isarSharedLogs.where().findAll();
      return isarLogs.map((p) {
        final clipsList = jsonDecode(p.clipsJson) as List<dynamic>;
        final viewersMap = jsonDecode(p.viewersJson) as Map<String, dynamic>;
        final reactionsMap = jsonDecode(p.reactionsJson) as Map<String, dynamic>;

        return SharedLog(
          id: p.shareId,
          ownerUid: p.ownerUid,
          ownerUsername: p.ownerUsername,
          date: p.date,
          expiresAt: p.expiresAt,
          clips: clipsList.map((c) => SharedClip.fromMap(Map<String, dynamic>.from(c))).toList(),
          viewers: viewersMap,
          reactions: reactionsMap,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> cacheMyLogs(List<DayLog> logs) async {
    try {
      final isarLogs = logs.map((l) => IsarDayLog()
        ..logId = l.id
        ..date = l.date
        ..isClosed = l.isClosed
        ..closedAt = l.closedAt
        ..clipCount = l.clipCount
        ..thumbnailUrl = l.thumbnailUrl
        ..updatedAt = DateTime.now()
      ).toList();

      await isar.writeTxn(() async {
        await isar.isarDayLogs.putAll(isarLogs);
      });
    } catch (_) {}
  }

  Future<List<DayLog>> getCachedMyLogs() async {
    try {
      // Assuming sorting by date in memory if no index exists, or we can just fetch all and let Dart sort
      final isarLogs = await isar.isarDayLogs.where().findAll();
      final logs = isarLogs.map((p) => DayLog(
        id: p.logId,
        date: p.date,
        isClosed: p.isClosed,
        closedAt: p.closedAt,
        clipCount: p.clipCount,
        thumbnailUrl: p.thumbnailUrl,
      )).toList();
      logs.sort((a, b) => b.date.compareTo(a.date));
      return logs;
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearAll() async {
    try {
      await isar.writeTxn(() async {
        await isar.clear();
      });
    } catch (_) {}
  }
}
