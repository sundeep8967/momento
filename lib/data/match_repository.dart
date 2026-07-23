import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Joins the matchmaking pool with the given location
  Future<void> joinMatchmaking(double lat, double lng) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('chai_matches').doc(currentUserId).set({
      'uid': currentUserId,
      'lat': lat,
      'lng': lng,
      'timestamp': FieldValue.serverTimestamp(),
      'matchedWith': null,
    });
  }

  /// Leaves the matchmaking pool
  Future<void> leaveMatchmaking() async {
    if (currentUserId == null) return;
    
    await _firestore.collection('chai_matches').doc(currentUserId).delete();
  }

  /// Polls for a match or finds one nearby
  /// Returns the matched user's UID or null if not found
  Future<String?> findMatch(double myLat, double myLng) async {
    if (currentUserId == null) return null;

    // First check if someone already matched with us
    final myDoc = await _firestore.collection('chai_matches').doc(currentUserId).get();
    if (myDoc.exists && myDoc.data()?['matchedWith'] != null) {
      return myDoc.data()?['matchedWith'];
    }

    // Otherwise, query for active searchers (last 10 minutes)
    final tenMinsAgo = DateTime.now().subtract(const Duration(minutes: 10));
    
    final activeSearchers = await _firestore
        .collection('chai_matches')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(tenMinsAgo))
        .get();

    String? closestMatchId;
    double minDistance = double.infinity;

    for (var doc in activeSearchers.docs) {
      if (doc.id == currentUserId) continue; // Skip self
      
      final data = doc.data();
      if (data['matchedWith'] != null) continue; // Already matched
      
      double lat = data['lat'] ?? 0.0;
      double lng = data['lng'] ?? 0.0;
      
      double distance = Geolocator.distanceBetween(myLat, myLng, lat, lng);
      
      if (distance < minDistance) {
        minDistance = distance;
        closestMatchId = doc.id;
      }
    }

    if (closestMatchId != null) {
      // Update both documents to finalize match
      await _firestore.collection('chai_matches').doc(currentUserId).update({
        'matchedWith': closestMatchId
      });
      await _firestore.collection('chai_matches').doc(closestMatchId).update({
        'matchedWith': currentUserId
      });
    }

    return closestMatchId;
  }
}
