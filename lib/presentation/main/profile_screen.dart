import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/colors.dart';
import '../../data/friends_repository.dart';
import '../../data/cloudinary_service.dart';
import '../../data/local_cache.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _photoUrl;
  DateTime? _createdAt;
  int _currentStreak = 0;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await FriendsRepository.instance.getMyProfile();
      if (mounted) {
        setState(() {
          _username = profile?.username ?? 'Unknown';
          _photoUrl = profile?.photoUrl;
          _createdAt = profile?.createdAt;
          _currentStreak = profile?.currentStreak ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _username = 'Error loading';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final uploadedUrl = await CloudinaryService.uploadImage(image.path);
      await FriendsRepository.instance.updateProfilePicture(uploadedUrl);
      
      if (mounted) {
        setState(() {
          _photoUrl = uploadedUrl;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await LocalCache.clearAll();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go('/auth/landing');
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SetlogColors.authSurface,
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone. All your logs and data will be permanently deleted.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FriendsRepository.instance.deleteAccount();
        if (mounted) context.go('/auth/landing');
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account. You may need to log in again first.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SetlogColors.collectionsHomeBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: SetlogColors.collectionsHomeTextPrimary),
        title: const Text(
          'Profile',
          style: TextStyle(color: SetlogColors.collectionsHomeTextPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: SetlogColors.authSurface,
                              shape: BoxShape.circle,
                              image: _photoUrl != null && _photoUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _photoUrl == null || _photoUrl!.isEmpty
                                ? Center(
                                    child: Text(
                                      _username != null && _username!.isNotEmpty ? _username![0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        color: SetlogColors.authInk,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          if (_isUploading)
                            const CircularProgressIndicator(color: SetlogColors.authTerminalAccent),
                          if (!_isUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: SetlogColors.authInk,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: SetlogColors.collectionsHomeBackground, width: 3),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ).animate().scaleXY(end: 1.05, duration: 2000.ms, curve: Curves.easeInOut).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await context.push('/main/avatar-customizer');
                        _loadProfile();
                      },
                      icon: const Text('✨', style: TextStyle(fontSize: 18)),
                      label: const Text(
                        'Customize 3D Avatar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SetlogColors.momentoPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                    ).animate().fadeIn(delay: 150.ms).scale(),
                    const SizedBox(height: 16),
                    const Text(
                      'YOUR USERNAME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SetlogColors.collectionsHomeTextSecondary,
                        letterSpacing: 1.2,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: SetlogColors.collectionsHomeSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SetlogColors.authStrokeSoft),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '@$_username',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: SetlogColors.collectionsHomeTextPrimary,
                            ),
                          ),
                          if (_currentStreak > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.local_fire_department, color: SetlogColors.blueFlame, size: 24),
                            const SizedBox(width: 2),
                            Text(
                              '$_currentStreak',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: SetlogColors.authTerminalAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    
                    if (_createdAt != null) ...[
                      const SizedBox(height: 32),
                      const Text(
                        'MEMBER SINCE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: SetlogColors.collectionsHomeTextSecondary,
                          letterSpacing: 1.2,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_createdAt!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: SetlogColors.collectionsHomeTextPrimary,
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: SetlogColors.authInk,
                        onPressed: () {
                          if (_username != null) {
                            Share.share('Add me on Momento to see my private video logs! My username is @$_username.');
                          }
                        },
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(CupertinoIcons.share, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Share Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                    ),

                    const Spacer(),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: _signOut,
                        color: CupertinoColors.systemGrey6,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(CupertinoIcons.square_arrow_right, color: CupertinoColors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Sign Out',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: CupertinoColors.black),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: _deleteAccount,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(CupertinoIcons.delete, color: CupertinoColors.destructiveRed, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Delete Account',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: CupertinoColors.destructiveRed),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
