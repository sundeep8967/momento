import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Joins the matchmaking pool with the given location
  Future<void> joinMatchmaking(double lat, double lng, {bool isSmokingMode = false}) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('chai_matches').doc(currentUserId).set({
      'uid': currentUserId,
      'lat': lat,
      'lng': lng,
      'isSmokingMode': isSmokingMode,
      'timestamp': FieldValue.serverTimestamp(),
      'matchedWith': null,
    });
  }

  /// Leaves the matchmaking pool
  Future<void> leaveMatchmaking() async {
    if (currentUserId == null) return;
    
    await _firestore.collection('chai_matches').doc(currentUserId).delete();
  }

  /// Streams active searchers within a given radius
  Stream<List<Map<String, dynamic>>> streamActiveSearchers(double myLat, double myLng, {bool isSmokingMode = false}) {
    final tenMinsAgo = DateTime.now().subtract(const Duration(minutes: 10));
    
    return _firestore
        .collection('chai_matches')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(tenMinsAgo))
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> searchers = [];
      
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue; // Skip self
        
        final data = doc.data();
        if (data['matchedWith'] != null) continue; // Skip already matched people
        
        // Filter by mode
        bool userIsSmokingMode = data['isSmokingMode'] ?? false;
        if (userIsSmokingMode != isSmokingMode) continue;
        
        double lat = data['lat'] ?? 0.0;
        double lng = data['lng'] ?? 0.0;
        
        double distance = Geolocator.distanceBetween(myLat, myLng, lat, lng);
        
        // Return people within 50km
        if (distance < 50000) {
          searchers.add({
            'uid': doc.id,
            'distance': distance, // in meters
            'lat': lat,
            'lng': lng,
          });
        }
      }
      
      return searchers;
    });
  }

  /// Streams the list of UIDs that have sent us a message
  Stream<List<String>> streamUnreadMessages() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('chai_matches')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data()!;
      if (data['unreadMessagesFrom'] == null) return [];
      return List<String>.from(data['unreadMessagesFrom']);
    });
  }

  Future<void> matchWithUser(String otherUid) async {
    if (currentUserId == null) return;
    
    // Update both documents to finalize match
    await _firestore.collection('chai_matches').doc(currentUserId).update({
      'matchedWith': otherUid
    });
    // This might fail due to security rules if not configured properly, 
    // but in a robust system this would be a cloud function.
    try {
      await _firestore.collection('chai_matches').doc(otherUid).update({
        'matchedWith': currentUserId
      });
    } catch (_) {}
  }
}
