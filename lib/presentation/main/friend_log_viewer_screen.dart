import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/video_proxy_server.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/log_repository.dart';
import '../../data/friends_repository.dart';
import '../../data/reactions_repository.dart';
import '../../theme/colors.dart';
import 'dart:io' show Platform;
import 'package:flutter_animate/flutter_animate.dart';

const _kEmojis = ['🔥', '❤️', '😂', '😮', '😢', '👏'];

class FriendLogViewerScreen extends StatefulWidget {
  final String shareId;

  const FriendLogViewerScreen({super.key, required this.shareId});

  @override
  State<FriendLogViewerScreen> createState() => _FriendLogViewerScreenState();
}

class _FriendLogViewerScreenState extends State<FriendLogViewerScreen> {
  SharedLog? _log;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  VideoPlayerController? _nextController; // pre-buffered next clip
  bool _isLoading = true;
  bool _showEmojiPicker = false;
  
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final logs = await LogRepository.instance.getFriendsSharedLogs();
      final log = logs.firstWhere((l) => l.id == widget.shareId, orElse: () => throw Exception('Log not found'));
      if (mounted) {
        setState(() {
          _log = log;
          _isLoading = false;
        });
        _playClip(0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playClip(int index) async {
    if (_log == null || index >= _log!.clips.length) return;

    VideoPlayerController controller;

    // Use pre-buffered controller if available, otherwise initialize fresh
    if (_nextController != null) {
      controller = _nextController!;
      _nextController = null;
    } else {
      final clip = _log!.clips[index];
      final proxyUrl = VideoProxyServer.instance.getProxyUrl(clip.cloudUrl, clip.id);
      controller = VideoPlayerController.networkUrl(Uri.parse(proxyUrl));
      await controller.initialize();
    }

    controller.setLooping(false);
    bool _advanced = false;
    controller.addListener(() {
      if (!_advanced &&
          controller.value.isInitialized &&
          !controller.value.isPlaying &&
          controller.value.position >= controller.value.duration - const Duration(milliseconds: 100)) {
        _advanced = true;
        _advanceClip();
      }
    });

    // Dispose old, swap in new
    final old = _videoController;
    if (mounted) {
      setState(() => _videoController = controller);
      controller.play();
    }
    await old?.dispose();

    // Pre-buffer the NEXT clip in the background
    final nextIndex = index + 1;
    if (_log != null && nextIndex < _log!.clips.length) {
      final nextClip = _log!.clips[nextIndex];
      final nextProxyUrl = VideoProxyServer.instance.getProxyUrl(nextClip.cloudUrl, nextClip.id);
      final next = VideoPlayerController.networkUrl(Uri.parse(nextProxyUrl));
      next.initialize().then((_) {
        if (mounted) _nextController = next;
      });
    }
  }

  void _advanceClip() {
    if (_log == null) return;
    if (_currentIndex < _log!.clips.length - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex++);
      _playClip(_currentIndex);
    } else {
      _finishViewing();
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex--);
      _playClip(_currentIndex);
    }
  }

  Future<void> _finishViewing() async {
    await LogRepository.instance.markLogViewed(widget.shareId, _currentIndex);
    if (mounted) context.pop();
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Block User?', style: TextStyle(color: Colors.white)),
        content: const Text('You will no longer see their logs or receive requests from them. They will be removed from your friends list.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && _log != null) {
      try {
        await FriendsRepository.instance.blockUser(_log!.ownerUid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked')));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to block: $e')));
        }
      }
    }
  }

  Future<void> _react(String emoji) async {
    if (_log == null || _myUid == null) return;
    HapticFeedback.heavyImpact();
    final clipId = _log!.clips[_currentIndex].id;
    
    // Optimistic UI update
    setState(() {
      _log!.reactions[clipId] ??= {};
      _log!.reactions[clipId][_myUid!] = emoji; // Add exclamation mark
      _showEmojiPicker = false;
    });
    
    final me = await FriendsRepository.instance.getMyProfile();
    await ReactionsRepository.instance.addReaction(
      shareId: widget.shareId, 
      clipId: clipId, 
      emoji: emoji, 
      reactorUsername: me?.username ?? 'someone'
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _nextController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_log == null || _log!.clips.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Nothing to show', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go back', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    final log = _log!;
    final clips = log.clips;
    final currentClipId = clips[_currentIndex].id;
    final myReaction = log.reactions[currentClipId]?[_myUid];
    final caption = clips[_currentIndex].caption;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          if (_showEmojiPicker) {
            setState(() => _showEmojiPicker = false);
            return;
          }
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx > width / 2) {
            _advanceClip();
          } else {
            _goBack();
          }
        },
        onLongPress: () {
          HapticFeedback.lightImpact();
          setState(() => _showEmojiPicker = !_showEmojiPicker);
        },
        child: Stack(
          children: [
            // Video
            Center(
              child: _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // Real-time Reactions Stream
            if (currentClipId.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: StreamBuilder<List<Reaction>>(
                    stream: ReactionsRepository.instance.reactionsStream(widget.shareId, currentClipId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                      
                      final recentReactions = snapshot.data!.where((r) => 
                        DateTime.now().difference(r.reactedAt).inSeconds < 5
                      ).toList();

                      return Stack(
                        children: recentReactions.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          return Positioned(
                            bottom: 100.0,
                            right: 20.0 + (i * 10.0), // offset slightly for multiple
                            child: Text(r.emoji, style: const TextStyle(fontSize: 40))
                                .animate()
                                .fadeIn(duration: 200.ms)
                                .slideY(begin: 0, end: -3, duration: 1500.ms, curve: Curves.easeOut)
                                .fadeOut(delay: 1000.ms, duration: 500.ms),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),

            // Progress bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: List.generate(clips.length, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _currentIndex ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: SetlogColors.authTerminalAccent,
                        radius: 18,
                        child: Text(
                          log.ownerUsername.isNotEmpty ? log.ownerUsername[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: SetlogColors.authInk),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${log.ownerUsername}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            _formatDate(log.date),
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (Platform.isAndroid)
                        IconButton(
                          icon: const Icon(Icons.wallpaper, color: Colors.white),
                          onPressed: () async {
                            final cloudUrl = log.clips[_currentIndex].cloudUrl;
                            final lastDotIndex = cloudUrl.lastIndexOf('.');
                            final imageUrl = lastDotIndex != -1 
                                ? '${cloudUrl.substring(0, lastDotIndex)}.jpg' 
                                : cloudUrl;
                            try {
                              const channel = MethodChannel('com.setlog.momento/wallpaper');
                              await channel.invokeMethod('setWallpaper', {'url': imageUrl});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Wallpaper updated! 🤩'))
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to set wallpaper: $e'))
                                );
                              }
                            }
                          },
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: Colors.grey[900],
                        onSelected: (val) {
                          if (val == 'block') _blockUser();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'block',
                            child: Text('Block & Report', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _finishViewing,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Caption
            if (caption != null && caption.isNotEmpty && !_showEmojiPicker)
              Positioned(
                bottom: 120,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      caption,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // My reaction badge
            if (myReaction != null)
              Positioned(
                bottom: 40,
                left: 20,
                child: AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(myReaction, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),

            // Hint
            if (!_showEmojiPicker)
              Positioned(
                bottom: 32,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showEmojiPicker = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('😊', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 6),
                        Text('React', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),

            // Emoji Picker
            if (_showEmojiPicker)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _kEmojis.map((e) {
                        final isSelected = myReaction == e;
                        return GestureDetector(
                          onTap: () => _react(e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: EdgeInsets.all(isSelected ? 6.0 : 4.0),
                            decoration: isSelected
                                ? const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Text(e, style: TextStyle(fontSize: isSelected ? 30 : 26)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
