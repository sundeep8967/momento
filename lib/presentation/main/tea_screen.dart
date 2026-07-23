import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../theme/colors.dart';
import '../../data/match_repository.dart';
import '../../data/friends_repository.dart';
import '../../avatar_kit/momento_avatar.dart';
import '../../avatar_kit/avatar_widget.dart';

import '../../theme/smoking_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeaScreen extends ConsumerStatefulWidget {
  const TeaScreen({super.key});

  @override
  ConsumerState<TeaScreen> createState() => _TeaScreenState();
}

class _TeaScreenState extends ConsumerState<TeaScreen> {
  final MatchRepository _matchRepo = MatchRepository();
  bool _isSearching = false;
  String? _matchedUserId;
  UserProfile? _matchedUser;
  Position? _myPosition;
  
  // For visual stability, we assign a random angle to each UID once.
  final Map<String, double> _userAngles = {};

  @override
  void dispose() {
    _matchRepo.leaveMatchmaking();
    super.dispose();
  }

  Future<void> _startSearching() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return;
    }

    setState(() {
      _isSearching = true;
      _matchedUserId = null;
      _matchedUser = null;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _myPosition = position);
      await _matchRepo.joinMatchmaking(position.latitude, position.longitude);
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _stopSearching() {
    _matchRepo.leaveMatchmaking();
    setState(() {
      _isSearching = false;
      _myPosition = null;
    });
  }
  
  Future<void> _onUserTapped(String uid) async {
    _stopSearching();
    await _matchRepo.matchWithUser(uid);
    // Usually you'd fetch real profile, here we mock it if it's a mock user
    UserProfile? profile = await FriendsRepository.instance.getUserProfile(uid);
    setState(() {
      _matchedUserId = uid;
      _matchedUser = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmokingMode = ref.watch(smokingModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isSmokingMode ? 'Smoking Area' : 'Tea Room',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: _matchedUserId != null 
            ? _buildMatchFound()
            : _buildSearchState(),
      ),
    );
  }

  Widget _buildSearchState() {
    final isSmokingMode = ref.watch(smokingModeProvider);
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radar Rings
              if (_isSearching) ...[
                _buildRing(300),
                _buildRing(200),
                _buildRing(100),
              ],
              
              // Center User (Tea Cup or Smoking Icon)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SetlogColors.momentoPink.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  isSmokingMode ? Icons.smoking_rooms : Icons.emoji_food_beverage_outlined,
                  size: 50,
                  color: SetlogColors.momentoPink,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(end: 1.05, duration: 2.seconds, curve: Curves.easeInOut)
              .animate()
              .fadeIn(duration: 800.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
              
              // Streaming Avatars on Radar
              if (_isSearching && _myPosition != null)
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _matchRepo.streamActiveSearchers(_myPosition!.latitude, _myPosition!.longitude),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final users = snapshot.data!;
                    
                    return Stack(
                      children: users.map((user) {
                        return _buildRadarAvatar(user);
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            children: [
              Text(
                _isSearching 
                    ? (isSmokingMode ? 'Finding smokers...' : 'Finding chaiars...') 
                    : (isSmokingMode ? 'Take a Smoke Break' : 'Spill the Tea'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 12),
              
              Text(
                _isSearching 
                    ? (isSmokingMode ? 'Looking for nearby smokers...' : 'Looking for nearby chai lovers...') 
                    : (isSmokingMode ? 'Connect with smokers...' : 'Connect with chai lovers...'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

              const SizedBox(height: 48),

              GestureDetector(
                onTap: _isSearching ? _stopSearching : _startSearching,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSearching 
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : [SetlogColors.momentoPink, SetlogColors.snapViewerAccent],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSearching ? Colors.grey : SetlogColors.momentoPink).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    _isSearching ? 'Cancel' : 'Find Nearby',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRing(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: SetlogColors.momentoPink.withOpacity(0.1), width: 2),
      ),
    ).animate(onPlay: (c) => c.repeat())
     .scaleXY(begin: 0.8, end: 1.2, duration: 2.seconds, curve: Curves.easeOut)
     .fadeOut(duration: 2.seconds);
  }
  
  Widget _buildRadarAvatar(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    final distance = user['distance'] as double;
    
    // Generate and cache a random angle for visual stability
    if (!_userAngles.containsKey(uid)) {
      _userAngles[uid] = math.Random().nextDouble() * 2 * math.pi;
    }
    final angle = _userAngles[uid]!;
    
    // Map distance (0 to 50000m) to radius (50 to 150 visual pixels)
    // Closer distance = smaller radius (closer to center)
    double normalizedDistance = (distance / 50000.0).clamp(0.0, 1.0);
    double radius = 70 + (normalizedDistance * 100); 

    // Convert polar coordinates to cartesian for Positioned
    double dx = radius * math.cos(angle);
    double dy = radius * math.sin(angle);
    
    return Positioned(
      // We align to the center, so we shift by half the avatar size (25)
      left: (MediaQuery.of(context).size.width / 2) + dx - 25,
      top: (MediaQuery.of(context).size.height / 2 - 150) + dy - 25, // Offset for stack position
      child: GestureDetector(
        onTap: () => _onUserTapped(uid),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: SetlogColors.momentoPink.withOpacity(0.3),
                    blurRadius: 8,
                  )
                ]
              ),
              child: AvatarWidget(
                avatar: MomentoAvatar.fromSeed(uid),
                size: 50,
                showBorder: false,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${(distance/1000).toStringAsFixed(1)}km',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
    );
  }

  Widget _buildMatchFound() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Match Found! 🎉",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: SetlogColors.momentoPink,
            letterSpacing: -0.5,
          ),
        ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
        
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: SetlogColors.momentoPinkBorder.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              AvatarWidget(
                avatar: _matchedUser?.avatar ?? MomentoAvatar.fromSeed(_matchedUserId ?? ''),
                size: 100,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 16),
              
              Text(
                _matchedUser?.username != null ? '@${_matchedUser!.username}' : 'Chai Lover',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ).animate().fadeIn(delay: 500.ms),
              
              const SizedBox(height: 24),
              
              GestureDetector(
                onTap: () {
                  if (_matchedUserId != null) {
                    FriendsRepository.instance.sendFriendRequest(_matchedUserId!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: SetlogColors.momentoPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Add Friend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).scaleXY(begin: 0.9, end: 1.0),
        
        const SizedBox(height: 32),
        
        TextButton(
          onPressed: () {
            setState(() {
              _matchedUser = null;
              _matchedUserId = null;
            });
          },
          child: const Text(
            'Keep Searching',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }
}


