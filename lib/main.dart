import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Setup App Links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'momento' && uri.host == 'add' && uri.pathSegments.isNotEmpty) {
      final username = uri.pathSegments.first;
      appRouter.push('/friends/add/$username');
    }
  });

  runApp(const MomentoApp());
}

class MomentoApp extends StatelessWidget {
  const MomentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Momento',
      theme: setlogTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
