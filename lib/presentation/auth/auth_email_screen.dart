import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/encryption_service.dart';
import '../../data/crypto_state.dart';
import '../../theme/colors.dart';

class AuthEmailScreen extends StatefulWidget {
  const AuthEmailScreen({super.key});

  @override
  State<AuthEmailScreen> createState() => _AuthEmailScreenState();
}

class _AuthEmailScreenState extends State<AuthEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isSignUp) {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCredential.user;
        if (user != null) {
          // E2EE Key Generation
          final masterKey = EncryptionService.generateRandomKey();
          final kek = EncryptionService.deriveKey(password, email);
          final encryptedMasterKey = EncryptionService.encryptMasterKey(masterKey, kek);

          // Upload encrypted master key to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('keys')
              .doc('master')
              .set({'encryptedKey': encryptedMasterKey});

          // Set active master key in memory
          CryptoState.instance.setMasterKey(masterKey);
        }

        if (mounted) {
          context.go('/auth/username');
        }
      } else {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCredential.user;
        if (user != null) {
          // Retrieve encrypted master key from Firestore
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('keys')
              .doc('master')
              .get();

          final encryptedMasterKey = doc.data()?['encryptedKey'];
          if (encryptedMasterKey != null) {
            // Decrypt master key using derived KEK
            final kek = EncryptionService.deriveKey(password, email);
            final masterKey = EncryptionService.decryptMasterKey(encryptedMasterKey, kek);

            // Set active master key in memory
            CryptoState.instance.setMasterKey(masterKey);
          }
        }

        if (mounted) {
          context.go('/auth/permissions');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encryption error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.authCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
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
                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: SetlogColors.authInk,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Start preserving your memories'
                      : 'Log in to access your secure journals',
                  style: const TextStyle(
                    fontSize: 16,
                    color: SetlogColors.authMuted,
                  ),
                ),
                const SizedBox(height: 48),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: SetlogColors.authInk,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: SetlogColors.authMuted),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SetlogColors.authStrokeSoft, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SetlogColors.authTerminalAccent, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: SetlogColors.authInk,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: SetlogColors.authMuted),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SetlogColors.authStrokeSoft, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: SetlogColors.authTerminalAccent, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 48),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: SetlogColors.authButtonPrimaryText,
                          ),
                        )
                      : Text(_isSignUp ? 'Sign Up' : 'Log In'),
                ),
                const SizedBox(height: 16),

                // Toggle Mode button
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log In'
                        : 'Don\'t have an account? Sign Up',
                    style: const TextStyle(
                      color: SetlogColors.authInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
