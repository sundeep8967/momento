import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._internal();
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Note: Actual permission request is typically handled in UI (e.g. PermissionsScreen).
    // Here we just set up listeners if already granted, or for token updates.
    
    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToDatabase(newToken);
    });

    // If we already have permission, get initial token and save it
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized || 
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    }
  }

  Future<bool> requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
      return true;
    }
    return false;
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // ⚠️ WARNING: Client-side push notifications using Legacy API
  // Requires the FCM Server Key from Firebase Console -> Cloud Messaging.
  Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    const String serverKey = 'YOUR_SERVER_KEY_HERE'; // TODO: Replace this
    
    if (serverKey == 'YOUR_SERVER_KEY_HERE') {
      debugPrint('Skipping push notification: Server key not configured.');
      return;
    }

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': body,
              'title': title,
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done'
            },
            'to': targetToken,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
