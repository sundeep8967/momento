import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:momento/data/snap_repository.dart';
import 'package:momento/theme/colors.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/encryption_service.dart';

class SnapViewerScreen extends ConsumerStatefulWidget {
  final List<DirectSnap> snaps;

  const SnapViewerScreen({
    super.key,
    required this.snaps,
  });

  @override
  ConsumerState<SnapViewerScreen> createState() => _SnapViewerScreenState();
}

class _SnapViewerScreenState extends ConsumerState<SnapViewerScreen> {
  VideoPlayerController? _videoController;
  Timer? _imageTimer;
  bool _isPlaying = false;
  bool _isError = false;
  int _currentIndex = 0;
  final TextEditingController _replyController = TextEditingController();

  DirectSnap get currentSnap => widget.snaps[_currentIndex];

  @override
  void initState() {
    super.initState();
    if (widget.snaps.isNotEmpty) {
      _loadSnap();
    }
  }

  Future<void> _loadSnap() async {
    // Cancel any pending image timer from a previous snap
    _imageTimer?.cancel();

    // Detach and dispose the old video controller first
    _videoController?.removeListener(_videoListener);
    await _videoController?.dispose();
    _videoController = null;

    // Mark state synchronously — one rebuild only
    if (mounted) {
      setState(() {
        _isError = false;
        _isPlaying = false;
      });
    }

    // Mark as viewed (fire-and-forget, no await needed — it's a background write)
    unawaited(_markAsViewed());

    if (currentSnap.isVideo) {
      try {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(currentSnap.videoUrl));
        await _videoController!.initialize();
        _videoController!.setLooping(false);
        _videoController!.addListener(_videoListener);

        if (mounted) {
          setState(() => _isPlaying = true);
          _videoController!.play();
        }
      } catch (e) {
        if (mounted) setState(() => _isError = true);
      }
    } else {
      // Image: show for 5 seconds then advance
      _imageTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) _nextSnap();
      });
      if (mounted) setState(() {});
    }
  }

  void _videoListener() {
    if (!mounted) return;
    if (_videoController == null) return;

    final value = _videoController!.value;

    // ── Auto-advance: video has reached its end ──────────────────────────────
    // Use VideoPlayerValue.isPlaying (controller's own truth) not our cached flag.
    // position >= duration signals completion; add 50ms guard to avoid false triggers
    // when position briefly equals duration before the first frame.
    if (value.isInitialized &&
        !value.isPlaying &&
        value.duration.inMilliseconds > 0 &&
        value.position.inMilliseconds >= value.duration.inMilliseconds - 50) {
      _nextSnap();
      return;
    }

    // Sync local play state for UI (pause icon etc.)
    if (_isPlaying != value.isPlaying) {
      setState(() => _isPlaying = value.isPlaying);
    }
  }

  void _previousSnap() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _loadSnap();
    }
  }

  void _nextSnap() {
    if (_currentIndex < widget.snaps.length - 1) {
      _currentIndex++;
      _loadSnap();
    } else {
      context.pop();
    }
  }

  void _handleTap(TapUpDetails details, double maxWidth) {
    if (details.localPosition.dx < maxWidth * 0.3) {
      _previousSnap();
    } else {
      _nextSnap();
    }
  }

  void _handleLongPressDown() {
    if (currentSnap.isVideo && _videoController != null) {
      _videoController!.pause();
    } else {
      _imageTimer?.cancel();
    }
    // Also hide UI elements here if we wanted to
  }

  void _handleLongPressUp() {
    if (currentSnap.isVideo && _videoController != null) {
      _videoController!.play();
    } else {
      _imageTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) _nextSnap();
      });
    }
  }

  Future<void> _markAsViewed() async {
    if (!currentSnap.isViewed) {
      try {
        await ref.read(snapRepositoryProvider).markSnapAsViewed(currentSnap.id);
      } catch (e) {
        debugPrint('Error marking snap as viewed: $e');
      }
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendQuickReply(String text) async {
    final textSent = text.trim();
    if (textSent.isEmpty) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    _replyController.clear();
    FocusScope.of(context).unfocus();
    
    final targetUid = currentSnap.senderUid;
    final uids = [currentUser.uid, targetUid]..sort();
    final chatId = uids.join('_');
    final keyBytes = sha256.convert(utf8.encode('momento_e2e_secret_$chatId')).bytes;
    final chatKey = Uint8List.fromList(keyBytes);
    
    final encryptedPayload = EncryptionService.encryptPayload(textSent, chatKey);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'receiverId': targetUid,
      'encryptedText': encryptedPayload,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent!'), duration: Duration(seconds: 1)),
      );
    }
  }



  String _getPosterUrl(DirectSnap snap) {
    if (snap.videoUrl.isEmpty) return '';
    if (!snap.isVideo) return snap.videoUrl;
    if (snap.videoUrl.contains('/upload/')) {
      return snap.videoUrl
          .replaceAll('/upload/', '/upload/f_jpg,q_auto,so_0/')
          .replaceAll(RegExp(r'\.(mp4|mov|mkv|avi|webm)$', caseSensitive: false), '.jpg');
    }
    return snap.videoUrl;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final snap in widget.snaps) {
      final url = _getPosterUrl(snap);
      if (url.isNotEmpty && url.startsWith('http')) {
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.snaps.isEmpty) return const Scaffold(backgroundColor: Colors.black);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Dismissible(
        key: const Key('snap_viewer_dismiss'),
        direction: DismissDirection.vertical,
        onDismissed: (_) => context.pop(),
        child: Stack(
          fit: StackFit.expand,
          children: [
          // Instant Media Player & Poster Masking
          if (_isError)
            const Center(child: Text('Failed to load media', style: TextStyle(color: Colors.white)))
          else
            _buildMediaView(),
            
          // Top Overlay (Sender info)
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: SetlogColors.authSurface,
                  child: Text(
                    currentSnap.senderUsername.isNotEmpty ? currentSnap.senderUsername[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: SetlogColors.authInk),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSnap.senderUsername,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (currentSnap.groupName != null)
                      Text(
                        'in ${currentSnap.groupName}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),
          
          // Top Snapchat Segmented Progress Bar
          Positioned(
            top: 40,
            left: 12,
            right: 12,
            child: Row(
              children: List.generate(widget.snaps.length, (idx) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: idx == _currentIndex
                          ? SetlogColors.momentoPink
                          : (idx < _currentIndex ? Colors.white : Colors.white38),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Screenshot Alert Banner Simulation
          Positioned(
            top: 96,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ Screenshot alert sent to ${currentSnap.senderUsername}!'),
                    backgroundColor: SetlogColors.snapViewerAccent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SetlogColors.snapViewerAccent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.camera_viewfinder, color: SetlogColors.snapViewerAccent, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Tap to simulate Screenshot Notification',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Quick Reply & Heart Reaction Bar
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: TextField(
                      controller: _replyController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: _sendQuickReply,
                      decoration: const InputDecoration(
                        hintText: 'Send message...',
                        hintStyle: TextStyle(color: Colors.white60, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❤️ Reaction sent!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: SetlogColors.momentoPink,
                    ),
                    child: Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildMediaView() {
    final posterUrl = _getPosterUrl(currentSnap);
    final isVideo = currentSnap.isVideo;
    final isInitialized = _videoController != null && _videoController!.value.isInitialized;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTap(details, constraints.maxWidth),
          onLongPressDown: (_) => _handleLongPressDown(),
          onLongPressUp: () => _handleLongPressUp(),
          onLongPressCancel: () => _handleLongPressUp(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Player Layer (Active once initialized)
              if (isVideo && isInitialized)
                Transform.scale(
                  scaleX: currentSnap.isFrontCamera ? -1 : 1,
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),

              // 2. Instant Poster/Image Mask (Renders instantly 0ms, fades out when video starts)
              if (!isVideo || !isInitialized)
                Transform.scale(
                  scaleX: currentSnap.isFrontCamera ? -1 : 1,
                  child: Image.network(
                    posterUrl,
                    fit: BoxFit.contain,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
