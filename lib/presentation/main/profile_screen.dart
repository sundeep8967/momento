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
import '../../avatar_kit/avatar_widget.dart';
import '../../avatar_kit/momento_avatar.dart';

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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share, color: Colors.black87, size: 22),
            onPressed: () {
              if (_username != null) {
                Share.share('Add me on Momento to see my private moments! Username: @$_username');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SetlogColors.momentoPink))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // 1. Snapchat Profile Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            SetlogColors.momentoPink.withOpacity(0.12),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: SetlogColors.momentoPinkBorder.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar with Camera Edit Badge
                          GestureDetector(
                            onTap: _isUploading ? null : _pickAndUploadImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [SetlogColors.momentoPink, SetlogColors.snapViewerAccent],
                                    ),
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: AvatarWidget(
                                      avatar: MomentoAvatar.fromSeed(FirebaseAuth.instance.currentUser?.uid ?? ''),
                                      size: 100,
                                      showBorder: false,
                                    ),
                                  ),
                                ),
                                if (_isUploading)
                                  const CircularProgressIndicator(color: SetlogColors.momentoPink),
                                if (!_isUploading)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: SetlogColors.momentoPink,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: SetlogColors.momentoPink.withOpacity(0.4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.camera_fill,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 14),

                          // Username & Display
                          Text(
                            '@$_username',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.4,
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 10),

                          // Badges Row (Streak + Member Since)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_currentStreak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_currentStreak Streak',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_currentStreak > 0) const SizedBox(width: 8),
                              if (_createdAt != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: SetlogColors.momentoPink.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: SetlogColors.momentoPinkBorder, width: 1),
                                  ),
                                  child: Text(
                                    'Joined ${DateFormat('MMM yyyy').format(_createdAt!)}',
                                    style: const TextStyle(
                                      color: SetlogColors.momentoPink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Avatar Kit Customizer Banner
                    GestureDetector(
                      onTap: () async {
                        await context.push('/main/avatar-kit');
                        _loadProfile();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [SetlogColors.momentoPink, SetlogColors.snapViewerAccent],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: SetlogColors.momentoPink.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🎭', style: TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Momento Avatar Kit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Customize outfits, accessories & cap',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(CupertinoIcons.right_chevron, color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),

                    // 3. Apple HIG Style Settings List Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildProfileOptionRow(
                            icon: CupertinoIcons.share,
                            iconColor: SetlogColors.momentoPink,
                            title: 'Share Profile Link',
                            onTap: () {
                              if (_username != null) {
                                Share.share('Add me on Momento! Username: @$_username');
                              }
                            },
                          ),
                          Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.15)),
                          _buildProfileOptionRow(
                            icon: CupertinoIcons.person_crop_circle_badge_plus,
                            iconColor: Colors.blueAccent,
                            title: 'Find Friends',
                            onTap: () => context.push('/main/friends'),
                          ),
                          Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.15)),
                          _buildProfileOptionRow(
                            icon: CupertinoIcons.square_arrow_right,
                            iconColor: Colors.orange,
                            title: 'Sign Out',
                            onTap: _signOut,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 24),

                    // Delete Account Button (Subtle Red Action)
                    CupertinoButton(
                      onPressed: _deleteAccount,
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(CupertinoIcons.delete, color: CupertinoColors.destructiveRed, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileOptionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(CupertinoIcons.right_chevron, color: Colors.black26, size: 16),
    );
  }
}
