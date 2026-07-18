import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background pre-fetching stub
  debugPrint("Handling a background message: ${message.messageId}");
  
  if (message.data.containsKey('videoUrl')) {
    try {
      final videoUrl = message.data['videoUrl'];
      final uri = Uri.parse(videoUrl);
      final filename = uri.pathSegments.last;
      
      final docsDir = await getApplicationDocumentsDirectory();
      final localFile = File('${docsDir.path}/$filename');
      
      if (!localFile.existsSync()) {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          await localFile.writeAsBytes(response.bodyBytes);
          debugPrint("Background pre-fetch complete: $filename");
        }
      }
    } catch (e) {
      debugPrint("Background pre-fetch failed: $e");
    }
  }
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._internal();
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

  // ⚠️ WARNING: Client-side push notifications using Service Account (POC ONLY)
  // In production, this logic MUST be moved to a secure backend/Cloud Function.
  Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    try {
      // 1. Load service account from assets
      final serviceAccountString = await rootBundle.loadString('assets/service_account.json');
      final serviceAccount = jsonDecode(serviceAccountString);
      
      final clientEmail = serviceAccount['client_email'];
      final privateKey = serviceAccount['private_key'];
      final projectId = serviceAccount['project_id'];

      // 2. Create JWT to request OAuth2 token
      final jwt = JWT(
        {
          'iss': clientEmail,
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
          'aud': 'https://oauth2.googleapis.com/token',
          'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
          'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
      );

      final signedJwt = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);

      // 3. Exchange JWT for Access Token
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': signedJwt,
        },
      );

      if (tokenResponse.statusCode != 200) {
        debugPrint('Failed to get access token: ${tokenResponse.body}');
        return;
      }

      final accessToken = jsonDecode(tokenResponse.body)['access_token'];

      // 4. Send FCM v1 Message
      final fcmResponse = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': <String, dynamic>{
              'token': targetToken,
              'notification': <String, dynamic>{
                'title': title,
                'body': body,
              },
              'android': {
                'priority': 'high',
                'notification': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK'
                }
              },
              'apns': {
                'payload': {
                  'aps': {
                    'sound': 'default'
                  }
                }
              }
            }
          },
        ),
      );

      if (fcmResponse.statusCode != 200) {
        debugPrint('FCM Send Error: ${fcmResponse.body}');
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
