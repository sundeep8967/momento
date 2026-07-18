import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/colors.dart';
import '../../data/push_notification_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    _cameraGranted = await Permission.camera.isGranted;
    _micGranted = await Permission.microphone.isGranted;
    _notifGranted = await Permission.notification.isGranted;
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    final notifGranted = await PushNotificationService.instance.requestPermissions();

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _micGranted = micStatus.isGranted;
      _notifGranted = notifGranted;
    });

    if (_cameraGranted && _micGranted) {
      // Proceed to the onboarding flow if core permissions are granted
      if (mounted) context.go('/auth/onboarding');
    } else if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text('Camera and Microphone access are required to use Momento. Please enable them in your device settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            
            // Terminal-style output
            const Text(
              'Initialize system...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SetlogColors.authInk,
                fontFamily: 'monospace', // Gives the terminal vibe we saw in the APK
              ),
            ),
            const SizedBox(height: 32),
            
            _buildStatusLine('Camera Module', _cameraGranted),
            const SizedBox(height: 16),
            _buildStatusLine('Microphone Array', _micGranted),
            const SizedBox(height: 16),
            _buildStatusLine('Push Notifications', _notifGranted),
            
            const Spacer(flex: 2),
            
            ElevatedButton(
              onPressed: _requestPermissions,
              child: Text(
                (_cameraGranted && _micGranted) ? 'DONE' : 'GRANT ACCESS',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine(String label, bool isGranted) {
    return Row(
      children: [
        Text(
          isGranted ? '✓' : '×',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isGranted ? SetlogColors.authTerminalAccent : SetlogColors.authMuted,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: isGranted ? SetlogColors.authInk : SetlogColors.authMuted,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
