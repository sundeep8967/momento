import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'data/models/isar_models.dart';
import 'data/video_proxy_server.dart';
import 'data/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

late Isar isar;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [IsarDayLogSchema, IsarSharedLogSchema, IsarUserProfileSchema],
    directory: dir.path,
  );
  
  await VideoProxyServer.instance.start();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize Push Notifications
  await PushNotificationService.instance.initialize();
  
  // Setup App Links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'momento' && uri.host == 'add' && uri.pathSegments.isNotEmpty) {
      final username = uri.pathSegments.first;
      appRouter.push('/friends/add/$username');
    }
  });

  runApp(const ProviderScope(child: MomentoApp()));
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
