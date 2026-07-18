import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/friends_repository.dart';
import '../../theme/colors.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final username = _usernameController.text.trim().toLowerCase();
    final name = _nameController.text.trim();

    if (username.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters');
      return;
    }
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(username)) {
      setState(() => _error = 'Only letters, numbers, . and _ allowed');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final taken = await FriendsRepository.instance.isUsernameTaken(username);
      if (taken) {
        setState(() { _error = '@$username is already taken'; _isLoading = false; });
        return;
      }

      await FriendsRepository.instance.saveUserProfile(
        username: username,
        displayName: name,
      );

      if (mounted) context.go('/auth/permissions');
    } catch (e) {
      setState(() { _error = 'Something went wrong. Try again.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.authCanvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Set up your\nprofile',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: SetlogColors.authInk,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Friends will find you by your username.',
                style: TextStyle(fontSize: 16, color: SetlogColors.authMuted),
              ),
              const SizedBox(height: 52),

              // Name
              _buildField(
                controller: _nameController,
                label: 'Your name',
                hint: 'e.g. Ravi',
                prefixText: null,
              ),
              const SizedBox(height: 28),

              // Username
              _buildField(
                controller: _usernameController,
                label: 'Username',
                hint: 'e.g. ravi_x',
                prefixText: '@',
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB00020), fontSize: 13),
                ),
              ],

              const Spacer(),

              ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: SetlogColors.authButtonPrimaryText,
                        ),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SetlogColors.authMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: SetlogColors.authInk,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SetlogColors.authStrokeSoft, fontSize: 20),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: SetlogColors.authTerminalAccent,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: SetlogColors.authStrokeSoft, width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: SetlogColors.authInk, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
