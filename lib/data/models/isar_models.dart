import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class IsarDayLog {
  Id id = Isar.autoIncrement; 
  
  @Index(unique: true, replace: true)
  late String logId;
  
  late String date;
  late bool isClosed;
  DateTime? closedAt;
  late int clipCount;
  String? thumbnailUrl;
  
  late DateTime updatedAt;
}

@collection
class IsarSharedLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String shareId;
  
  late String ownerUid;
  late String ownerUsername;
  late String date;
  late DateTime expiresAt;
  late bool isViewedByMe;
  
  // Storing clips as a JSON string for simplicity in offline-first mode
  late String clipsJson; 
  late String viewersJson;
  late String reactionsJson;
}

@collection
class IsarUserProfile {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  late String username;
  late String displayName;
  String? photoUrl;
  late int currentStreak;
  late int longestStreak;
  String? lastLogDate;
}

/// Helper function to create an integer ID from a string
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}
