// File generated manually for com.ravana.momento.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWLwUA2EVujGPHjH13Cr4aKWm1IQkMT84',
    appId: '1:509991346553:android:55dc33f969d9f8ea3d8fa8',
    messagingSenderId: '509991346553',
    projectId: 'momento-a05e0',
    storageBucket: 'momento-a05e0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMNCZHxzLRwJRz3Tj9VkOeDrZLRvVkqTE',
    appId: '1:509991346553:ios:125f07929e2bac243d8fa8',
    messagingSenderId: '509991346553',
    projectId: 'momento-a05e0',
    storageBucket: 'momento-a05e0.firebasestorage.app',
    iosBundleId: 'com.ravana.momento',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCMNCZHxzLRwJRz3Tj9VkOeDrZLRvVkqTE',
    appId: '1:509991346553:ios:125f07929e2bac243d8fa8',
    messagingSenderId: '509991346553',
    projectId: 'momento-a05e0',
    storageBucket: 'momento-a05e0.firebasestorage.app',
    iosBundleId: 'com.ravana.momento',
  );
}
