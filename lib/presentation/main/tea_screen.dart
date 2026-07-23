import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../theme/colors.dart';
import '../../data/match_repository.dart';
import '../../data/friends_repository.dart';
import '../../avatar_kit/momento_avatar.dart';
import '../../avatar_kit/avatar_widget.dart';

class TeaScreen extends StatefulWidget {
  const TeaScreen({super.key});

  @override
  State<TeaScreen> createState() => _TeaScreenState();
}

class _TeaScreenState extends State<TeaScreen> {
  final MatchRepository _matchRepo = MatchRepository();
  bool _isSearching = false;
  String? _matchedUserId;
  UserProfile? _matchedUser;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _matchRepo.leaveMatchmaking();
    super.dispose();
  }

  Future<void> _startSearching() async {
    // 1. Check permissions
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }

    setState(() {
      _isSearching = true;
      _matchedUserId = null;
      _matchedUser = null;
    });

    try {
      // 2. Get current location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 3. Join matchmaking pool
      await _matchRepo.joinMatchmaking(position.latitude, position.longitude);

      // 4. Start polling for matches every 3 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        final matchId = await _matchRepo.findMatch(position.latitude, position.longitude);
        if (matchId != null) {
          timer.cancel();
          final profile = await FriendsRepository.instance.getUserProfile(matchId);
          if (mounted) {
            setState(() {
              _isSearching = false;
              _matchedUserId = matchId;
              _matchedUser = profile;
            });
          }
        }
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _stopSearching() {
    _pollingTimer?.cancel();
    _matchRepo.leaveMatchmaking();
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Tea Room',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: _matchedUser != null 
            ? _buildMatchFound()
            : _buildSearchState(),
      ),
    );
  }

  Widget _buildSearchState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (_isSearching)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SetlogColors.momentoPink.withOpacity(0.2),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .scaleXY(begin: 0.5, end: 1.5, duration: 1.5.seconds, curve: Curves.easeOut)
               .fadeOut(duration: 1.5.seconds),
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
              child: const Icon(
                Icons.emoji_food_beverage_outlined,
                size: 80,
                color: SetlogColors.momentoPink,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(end: 1.05, duration: 2.seconds, curve: Curves.easeInOut)
            .animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.2, curve: Curves.easeOutCubic),
          ],
        ),
        
        const SizedBox(height: 32),
        
        Text(
          _isSearching ? 'Finding chaiars...' : 'Spill the Tea',
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
              ? 'Looking for nearby chai lovers...' 
              : 'Connect with chai lovers...',
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                _matchedUser?.username != null ? '@${_matchedUser!.username}' : 'Unknown User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ).animate().fadeIn(delay: 500.ms),
              
              const SizedBox(height: 24),
              
              GestureDetector(
                onTap: () {
                  // E.g., open their profile or send friend request
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

