import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

class AuthSignupScreen extends StatefulWidget {
  const AuthSignupScreen({super.key});

  @override
  State<AuthSignupScreen> createState() => _AuthSignupScreenState();
}

class _AuthSignupScreenState extends State<AuthSignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: SetlogColors.authInk),
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'What should we call you?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: SetlogColors.authInk,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your name helps your friends recognize you.',
              style: TextStyle(
                fontSize: 16,
                color: SetlogColors.authMuted,
              ),
            ),
            const SizedBox(height: 48),
            
            // Form Fields
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name',
              autoFocus: true,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name',
            ),
            
            const Spacer(),
            
            // Continue Button
            ElevatedButton(
              onPressed: () {
                // In a real app, save the name to state here.
                // Then continue to the permission gate.
                context.go('/auth/permissions');
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool autoFocus = false,
  }) {
    return TextField(
      controller: controller,
      autofocus: autoFocus,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: SetlogColors.authInk,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: SetlogColors.authMuted),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: SetlogColors.authStrokeSoft, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: SetlogColors.authTerminalAccent, width: 2),
        ),
      ),
    );
  }
}
